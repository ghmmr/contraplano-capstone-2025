import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/validators.dart';

void main() {
  group('Validators - pruebas unitarias locales', () {
    test('requiredField devuelve error si está vacío', () {
      expect(requiredField(''), 'Campo obligatorio');
    });

    test('requiredField devuelve null si tiene texto', () {
      expect(requiredField('Contraplano'), null);
    });

    test('requiredHttps devuelve error si no es HTTPS', () {
      expect(requiredHttps('http://example.com'), 'Debe ser una URL https://');
    });

    test('requiredHttps devuelve null si es HTTPS válido', () {
      expect(requiredHttps('https://contraplano.cl'), null);
    });

    test('requiredImageUrl valida extensiones de imagen', () {
      expect(requiredImageUrl('https://site.com/image.png'), null);
      expect(
        requiredImageUrl('https://site.com/file.txt'),
        'Debe ser imagen .png o .jpg',
      );
    });

    test('optionalYoutubeUrl detecta YouTube correctamente', () {
      expect(optionalYoutubeUrl('https://youtu.be/abc123'), null);
      expect(
        optionalYoutubeUrl('https://twitter.com/video'),
        'La URL no parece de YouTube',
      );
    });
  });
}
