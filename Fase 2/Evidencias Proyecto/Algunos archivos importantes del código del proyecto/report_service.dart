// lib/services/report_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:mrc_contraplano/utils/url_canonical.dart';

class DuplicateReportException implements Exception {
  final String canonicalUrl;
  final String? existingReportId;
  DuplicateReportException(this.canonicalUrl, {this.existingReportId});
  @override
  String toString() => 'DuplicateReportException';
}

class ReportService {
  final _db = FirebaseFirestore.instance;

  // TTL helper
  Timestamp _ttl90() =>
      Timestamp.fromDate(DateTime.now().toUtc().add(const Duration(days: 90)));

  Future<void> createReport({
    required String title,
    required String block,
    required Map<String, String?> links,
    required String? newsletterDesc,
    required String createdByName,
    String source = 'manual',
  }) async {
    await _db.collection('reports').add({
      'title': title.trim(),
      'block': block.trim(),
      'links': links,
      'newsletter_desc': newsletterDesc,
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': _ttl90(),           // TTL 90d
      'state': 'valido',                // para filtros
      'author': createdByName.trim(),   // redundante para búsq. simple
      'created_by': {'name': createdByName.trim(), 'source': source},
      'source': source,
    });
    await _db.collection('audit_logs').add({
      'ts': FieldValue.serverTimestamp(),
      'action': 'create_report',
      'entity_type': 'report',
      'actor': createdByName.trim(),
      'meta': {'title': title.trim(), 'block': block.trim()},
    });
  }

  Future<void> createReportDedup({
    required String title,
    required String block,
    required Map<String, String?> links,
    required String? newsletterDesc,
    required String createdByName,
    String source = 'manual',
    String? wpUserId,
    String? wpDisplayName,
  }) async {
    final noticiaUrl = links['noticia'];
    if (noticiaUrl == null || noticiaUrl.trim().isEmpty) {
      throw 'URL de noticia requerida';
    }
    final canonical = canonicalizeUrl(noticiaUrl);
    final hash = sha1.convert(utf8.encode(canonical)).toString();

    final hashes = _db.collection('report_hashes').doc(hash);
    final reports = _db.collection('reports').doc();
    final audits  = _db.collection('audit_logs').doc();

    await _db.runTransaction((tx) async {
      final hSnap = await tx.get(hashes);
      if (hSnap.exists) {
        final data = hSnap.data() as Map<String, dynamic>?;
        throw DuplicateReportException(canonical, existingReportId: data?['reportId'] as String?);
      }

      tx.set(hashes, {
        'canonical_url': canonical,
        'createdAt': FieldValue.serverTimestamp(),
        'reportId': reports.id,
        'source': source,
        if (wpUserId != null) 'wp_user_id': wpUserId,
      });

      tx.set(reports, {
        'title': title.trim(),
        'block': block.trim(),
        'links': links,
        'newsletter_desc': newsletterDesc,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': _ttl90(),                 // TTL 90d
        'state': 'valido',
        'author': (wpDisplayName ?? createdByName).trim(),
        'created_by': {
          'name': createdByName.trim(),
          'source': source,
        },
        'source': source,
        'canonical_url': canonical,
        'canonical_hash': hash,
        if (wpUserId != null) 'wp_user_id': wpUserId,
        if (wpDisplayName != null) 'wp_display_name': wpDisplayName,
      });

      tx.set(audits, {
        'ts': FieldValue.serverTimestamp(),
        'action': 'create_report',
        'entity_type': 'report',
        'actor': createdByName.trim(),
        'result': 'ok',
        'source': source,
        'reportId': reports.id,
        'meta': {'title': title.trim(), 'block': block.trim(), 'canonical_hash': hash},
        if (wpUserId != null) 'wp_user_id': wpUserId,
        if (wpDisplayName != null) 'wp_display_name': wpDisplayName,
      });
    });
  }
}
