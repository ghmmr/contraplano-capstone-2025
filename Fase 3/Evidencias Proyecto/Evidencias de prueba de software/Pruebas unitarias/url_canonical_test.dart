import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/url_canonical.dart';

void main() {
  group('canonicalizeUrl – normalización básica', () {
    test('host y scheme en minúsculas', () {
      final url = canonicalizeUrl("HTTPS://CONTRAPLANO.CL/NOTICIA");
      expect(url, "https://contraplano.cl/NOTICIA");
    });

    test('elimina slash final del path', () {
      final url = canonicalizeUrl("https://contraplano.cl/noticia/");
      expect(url, "https://contraplano.cl/noticia");
    });

    test('path vacío queda como "/"', () {
      final url = canonicalizeUrl("https://contraplano.cl/");
      expect(url, "https://contraplano.cl/");
    });
  });

  group('canonicalizeUrl – eliminación de parámetros UTM y tracking', () {
    test('elimina utm_source', () {
      final url = canonicalizeUrl(
          "https://contraplano.cl/x?utm_source=facebook&id=123");
      expect(url, "https://contraplano.cl/x?id=123");
    });

    test('elimina fbclid', () {
      final url = canonicalizeUrl(
          "https://contraplano.cl/x?fbclid=ABC123&id=45");
      expect(url, "https://contraplano.cl/x?id=45");
    });

    test('elimina múltiples parámetros tracking pero deja otros', () {
      final url = canonicalizeUrl(
          "https://contraplano.cl/x?utm_source=fb&gclid=ZXC&dato=1&extra=2");
      expect(url, "https://contraplano.cl/x?dato=1&extra=2");
    });

    test('si solo había tracking params → query queda vacía', () {
      final url = canonicalizeUrl(
          "https://contraplano.cl/x?utm_source=fb&gclid=123&fbclid=ZZZ");
      expect(url, "https://contraplano.cl/x");
    });
  });

  group('canonicalizeUrl – fragmentos (#)', () {
    test('elimina fragmento', () {
      final url = canonicalizeUrl("https://contraplano.cl/noticia#seccion1");
      expect(url, "https://contraplano.cl/noticia");
    });
  });

  group('canonicalizeUrl – puertos', () {
    test('elimina puerto 80 y 443', () {
      expect(
        canonicalizeUrl("http://contraplano.cl:80/noticia"),
        "http://contraplano.cl/noticia",
      );
      expect(
        canonicalizeUrl("https://contraplano.cl:443/noticia"),
        "https://contraplano.cl/noticia",
      );
    });

    test('mantiene puertos no estándar', () {
      expect(
        canonicalizeUrl("https://contraplano.cl:8080/noticia"),
        "https://contraplano.cl:8080/noticia",
      );
    });
  });

  group('canonicalizeUrl – robustez', () {
    test('URL inválida → retorna original (trimmed)', () {
      expect(
        canonicalizeUrl("esto no es una url"),
        "esto no es una url",
      );
    });

    test('URL sin scheme → retorna original', () {
      expect(
        canonicalizeUrl("contraplano.cl/noticia"),
        "contraplano.cl/noticia",
      );
    });
  });
}
