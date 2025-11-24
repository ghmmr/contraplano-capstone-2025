import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:mrc_contraplano/services/config_service.dart';

void main() {
  group('ConfigService – getBlocks()', () {
    test('retorna lista vacía si no existe el documento', () async {
      final fake = FakeFirebaseFirestore();
      final service = ConfigService(db: fake);

      final result = await service.getBlocks();
      expect(result, isEmpty);
    });

    test('retorna la lista guardada en Firestore', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('config').doc('categories').set({
        'list': ['Noticias', 'Deportes', 'Economía']
      });

      final service = ConfigService(db: fake);
      final result = await service.getBlocks();

      expect(result, ['Noticias', 'Deportes', 'Economía']);
    });
  });

  group('ConfigService – setBlocks()', () {
    test('guarda la lista en Firestore', () async {
      final fake = FakeFirebaseFirestore();
      final service = ConfigService(db: fake);

      await service.setBlocks(['A', 'B', 'C']);

      final snap = await fake.collection('config').doc('categories').get();
      expect(snap.data()?['list'], ['A', 'B', 'C']);
    });
  });

  group('ConfigService – getFieldPolicies()', () {
    test('retorna defaults si el documento no existe', () async {
      final fake = FakeFirebaseFirestore();
      final service = ConfigService(db: fake);

      final result = await service.getFieldPolicies();

      expect(result.length, service.defaultFieldPolicies.length);
      expect(result['noticia']!.required, true);
    });

    test('mezcla defaults con políticas personalizadas', () async {
      final fake = FakeFirebaseFirestore();

      // Documento parcial
      await fake.collection('config').doc('social_policies').set({
        'fields': {
          'linkedin': {
            'required': true,
            'label': 'LinkedIn personalizado'
          }
        }
      });

      final service = ConfigService(db: fake);
      final result = await service.getFieldPolicies();

      // Se mantiene default de "noticia"
      expect(result['noticia']!.required, true);

      // Se aplica valor personalizado
      expect(result['linkedin']!.required, true);
      expect(result['linkedin']!.label, 'LinkedIn personalizado');
    });
  });

  group('ConfigService – setFieldPolicies()', () {
    test('convierte FieldPolicy correctamente y lo guarda en Firestore',
        () async {
      final fake = FakeFirebaseFirestore();
      final service = ConfigService(db: fake);

      final policies = {
        'x': const FieldPolicy(required: false, label: 'X (Twitter)'),
        'instagram': const FieldPolicy(required: true, label: 'Instagram')
      };

      await service.setFieldPolicies(policies);

      final snap =
          await fake.collection('config').doc('social_policies').get();

      final stored = snap.data()?['fields'] as Map<String, dynamic>;

      expect(stored['x']['required'], false);
      expect(stored['x']['label'], 'X (Twitter)');

      expect(stored['instagram']['required'], true);
      expect(stored['instagram']['label'], 'Instagram');
    });
  });

  group('FieldPolicy – conversiones', () {
    test('fromMap funciona correctamente', () {
      final policy =
          FieldPolicy.fromMap({'required': true, 'label': 'Test Label'});

      expect(policy.required, true);
      expect(policy.label, 'Test Label');
    });

    test('toMap exporta los valores correctamente', () {
      const policy = FieldPolicy(required: false, label: 'Campo X');
      final map = policy.toMap();

      expect(map['required'], false);
      expect(map['label'], 'Campo X');
    });
  });
}
