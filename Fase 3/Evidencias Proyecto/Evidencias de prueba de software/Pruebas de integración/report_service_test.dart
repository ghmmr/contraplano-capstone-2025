import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/services/report_service.dart';
import 'package:mrc_contraplano/utils/url_canonical.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  group('ReportService – createReport', () {
    test('crea reporte y audit log correctamente', () async {
      final fake = FakeFirebaseFirestore();
      final service = ReportService(firestore: fake);

      await service.createReport(
        title: "Noticia Test",
        block: "Ciencia",
        links: {
          "noticia": "https://contraplano.cl/x",
          "podcast": "https://radio.cl/p",
        },
        newsletterDesc: "Texto newsletter",
        createdByName: "Gabriel",
        rankMath: 85,
      );

      final reports = await fake.collection('reports').get();
      final audits = await fake.collection('audit_logs').get();

      expect(reports.docs.length, 1);
      expect(audits.docs.length, 1);

      final r = reports.docs.first.data();
      expect(r['title'], "Noticia Test");
      expect(r['block'], "Ciencia");
      expect(r['rank_math'], 85);
      expect(r['links']['noticia'], "https://contraplano.cl/x");

      expect(r['state'], "valido");
      expect(r['author'], "Gabriel");

      final expires = (r['expires_at'] as Timestamp).toDate();
      final diff = expires.difference(DateTime.now().toUtc()).inDays;
      expect(diff >= 89 && diff <= 91, true);
    });
  });

  group('ReportService – createReportDedup', () {
    test('crea reporte, hash y audit log correctamente', () async {
      final db = FakeFirebaseFirestore();
      final service = ReportService(firestore: db);

      final url = "https://contraplano.cl/noticia/123?utm_source=fb";

      final canonical = canonicalizeUrl(url);
      final hash = sha1.convert(utf8.encode(canonical)).toString();

      await service.createReportDedup(
        title: "Test DEDUP",
        block: "Ciencia",
        links: {"noticia": url},
        newsletterDesc: null,
        createdByName: "Gabriel",
      );

      final hSnap = await db.collection('report_hashes').doc(hash).get();
      expect(hSnap.exists, true);
      expect(hSnap.data()!['canonical_url'], canonical);

      final reports = await db.collection('reports').get();
      expect(reports.docs.length, 1);

      final r = reports.docs.first.data();
      expect(r['canonical_url'], canonical);
      expect(r['canonical_hash'], hash);

      final audits = await db.collection('audit_logs').get();
      expect(audits.docs.length, 1);
    });

    test('lanza DuplicateReportException si ya existe', () async {
      final db = FakeFirebaseFirestore();
      final service = ReportService(firestore: db);

      final url = "https://contraplano.cl/noticia/10?utm_medium=x";

      final canonical = canonicalizeUrl(url);
      final hash = sha1.convert(utf8.encode(canonical)).toString();

      await db.collection('report_hashes').doc(hash).set({
        'canonical_url': canonical,
        'reportId': 'abc123'
      });

      try {
        await service.createReportDedup(
          title: "X",
          block: "Y",
          links: {"noticia": url},
          newsletterDesc: null,
          createdByName: "Gabriel",
        );
        fail("Debió lanzar DuplicateReportException");
      } catch (e) {
        expect(e is DuplicateReportException, true);
        final ex = e as DuplicateReportException;
        expect(ex.canonicalUrl, canonical);
        expect(ex.existingReportId, "abc123");
      }
    });

    test('guarda campos WP si se envían', () async {
      final db = FakeFirebaseFirestore();
      final service = ReportService(firestore: db);

      await service.createReportDedup(
  title: "WP",
  block: "Blog",
  links: {"noticia": "https://contraplano.cl/x"},
  newsletterDesc: null,
  createdByName: "Admin",   // <-- AGREGA ESTA COMA
  wpUserId: "55",
  wpDisplayName: "EditorWP",
);


      final reports = await db.collection('reports').get();
      final r = reports.docs.first.data();

      expect(r['wp_user_id'], "55");
      expect(r['wp_display_name'], "EditorWP");
    });
  });
}