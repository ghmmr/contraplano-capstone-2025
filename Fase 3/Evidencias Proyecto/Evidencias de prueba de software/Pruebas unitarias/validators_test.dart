import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/validators.dart';

void main() {
  group('requiredField', () {
    test('retorna error si está vacío', () {
      expect(requiredField(''), 'Campo obligatorio');
    });

    test('retorna null si tiene contenido', () {
      expect(requiredField('hola'), null);
    });
  });

  group('requiredHttps', () {
    test('URL vacía → obligatorio', () {
      expect(requiredHttps(''), 'Campo obligatorio');
    });

    test('URL sin https → error', () {
      expect(requiredHttps('http://google.com'), 'Debe ser una URL https://');
    });

    test('URL con https → OK', () {
      expect(requiredHttps('https://google.com'), null);
    });
  });

  group('requiredHttpsWithDomain', () {
    test('URL vacía → obligatorio', () {
      expect(
        requiredHttpsWithDomain('', 'contraplano.cl'),
        'Campo obligatorio',
      );
    });

    test('URL sin https → error', () {
      expect(
        requiredHttpsWithDomain('http://contraplano.cl', 'contraplano.cl'),
        'Debe ser una URL https://',
      );
    });

    test('Dominio incorrecto → error', () {
      expect(
        requiredHttpsWithDomain('https://google.com', 'contraplano.cl'),
        'La URL no parece de contraplano.cl',
      );
    });

    test('Dominio correcto → null', () {
      expect(
        requiredHttpsWithDomain(
          'https://www.contraplano.cl/noticia',
          'contraplano.cl',
        ),
        null,
      );
    });
  });

  group('requiredImageUrl', () {
    test('Vacía → obligatorio', () {
      expect(requiredImageUrl(''), 'Campo obligatorio');
    });

    test('Sin https → error', () {
      expect(
        requiredImageUrl('http://site.com/img.png'),
        'Debe ser una URL https://',
      );
    });

    test('Extensión inválida → error', () {
      expect(
        requiredImageUrl('https://site.com/img.gif'),
        'Debe ser imagen .png o .jpg',
      );
    });

    test('Extensión válida → OK', () {
      expect(requiredImageUrl('https://site.com/img.jpeg'), null);
      expect(requiredImageUrl('https://site.com/img.jpg'), null);
      expect(requiredImageUrl('https://site.com/img.png'), null);
    });
  });

  group('optionalYoutubeUrl', () {
    test('Vacío → OK', () {
      expect(optionalYoutubeUrl(''), null);
    });

    test('URL sin https → error', () {
      expect(
        optionalYoutubeUrl('http://youtu.be/abc123'),
        'Debe ser una URL https://',
      );
    });

    test('Host inválido → error', () {
      expect(
        optionalYoutubeUrl('https://google.com/watch?v=123'),
        'La URL debe ser youtu.be/<id> o youtube.com/(watch?v=… | shorts/… | embed/… | live/…)',
      );
    });

    test('youtu.be válido → OK', () {
      expect(optionalYoutubeUrl('https://youtu.be/abcdEF123'), null);
    });

    test('watch?v= válido → OK', () {
      expect(
        optionalYoutubeUrl('https://www.youtube.com/watch?v=XYZ123'),
        null,
      );
    });

    test('shorts válido → OK', () {
      expect(
        optionalYoutubeUrl('https://youtube.com/shorts/ABC987'),
        null,
      );
    });

    test('embed válido → OK', () {
      expect(
        optionalYoutubeUrl('https://www.youtube.com/embed/ABC987'),
        null,
      );
    });

    test('live válido → OK', () {
      expect(
        optionalYoutubeUrl('https://www.youtube.com/live/ABC987'),
        null,
      );
    });
  });

  group('optionalXWithAccount', () {
    test('Vacío → OK', () {
      expect(optionalXWithAccount('', 'contraplanotv'), null);
    });

    test('Host incorrecto → error', () {
      expect(
        optionalXWithAccount('https://google.com/user', 'contraplanotv'),
        'La URL debe ser de x.com',
      );
    });

    test('Falta cuenta → error', () {
      expect(
        optionalXWithAccount('https://x.com/otraCuenta', 'contraplanotv'),
        'La URL debe contener contraplanotv',
      );
    });

    test('Cuenta correcta → OK', () {
      expect(
        optionalXWithAccount('https://x.com/contraplanotv', 'contraplanotv'),
        null,
      );
    });
  });

  group('requiredRankMath', () {
    test('Vacío → obligatorio', () {
      expect(requiredRankMath(''), 'Campo obligatorio');
    });

    test('No numérico → error', () {
      expect(requiredRankMath('abc'), 'Solo números');
    });

    test('Fuera de rango (0) → error', () {
      expect(requiredRankMath('0'), 'Debe ser un entero entre 1 y 100');
    });

    test('Fuera de rango (101) → error', () {
      expect(requiredRankMath('101'), 'Debe ser un entero entre 1 y 100');
    });

    test('Dentro de rango → OK', () {
      expect(requiredRankMath('50'), null);
    });
  });

  group('optionalRankMath', () {
    test('Vacío → OK', () {
      expect(optionalRankMath(''), null);
    });

    test('No numérico → error', () {
      expect(optionalRankMath('abc'), 'Solo números');
    });

    test('Fuera de rango (0) → error', () {
      expect(optionalRankMath('0'), 'Debe ser 1..100');
    });

    test('Dentro de rango → OK', () {
      expect(optionalRankMath('100'), null);
    });
  });
}
