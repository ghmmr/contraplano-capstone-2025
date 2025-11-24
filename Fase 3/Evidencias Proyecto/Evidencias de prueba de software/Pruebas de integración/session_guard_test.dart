// test/features/auth/session_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mrc_contraplano/features/auth/session_guard.dart';

void main() {
  group('verifySession()', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    test('crea la sesión si no existe (primer uso)', () async {
      final result = await verifySession(
        sessionId: 'abc123',
        isAdmin: false,
        firestore: fakeDb,
        mockUid: 'UID_A',
      );

      expect(result, SessionCheckResult.ok);

      final snap = await fakeDb.collection('sessions').doc('abc123').get();
      expect(snap.exists, true);
      expect(snap.data()?['uid'], 'UID_A');
      expect(snap.data()?['mode'], 'reporter');
    });

    test('permite acceso si uid y modo coinciden', () async {
      await fakeDb.collection('sessions').doc('sess1').set({
        'uid': 'U1',
        'mode': 'admin',
      });

      final result = await verifySession(
        sessionId: 'sess1',
        isAdmin: true,
        firestore: fakeDb,
        mockUid: 'U1',
      );

      expect(result, SessionCheckResult.ok);
    });

    test('rechaza si el uid es distinto', () async {
      await fakeDb.collection('sessions').doc('sess1').set({
        'uid': 'U1',
        'mode': 'admin',
      });

      final result = await verifySession(
        sessionId: 'sess1',
        isAdmin: true,
        firestore: fakeDb,
        mockUid: 'U2', // ← UID diferente
      );

      expect(result, SessionCheckResult.takenByOther);
    });

    test('rechaza si el rol no coincide', () async {
      await fakeDb.collection('sessions').doc('sess1').set({
        'uid': 'U1',
        'mode': 'admin',
      });

      final result = await verifySession(
        sessionId: 'sess1',
        isAdmin: false, // ← modo incorrecto
        firestore: fakeDb,
        mockUid: 'U1',
      );

      expect(result, SessionCheckResult.takenByOther);
    });

    test('devuelve error si uid viene nulo (sin mockUid y sin FirebaseAuth)', () async {
      final result = await verifySession(
        sessionId: 'sess1',
        isAdmin: false,
        firestore: fakeDb,
        mockUid: null, // fuerza error
      );

      expect(result, SessionCheckResult.error);
    });
  });
}
