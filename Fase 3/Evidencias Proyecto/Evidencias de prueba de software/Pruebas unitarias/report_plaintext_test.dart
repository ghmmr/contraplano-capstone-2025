import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/report_plaintext.dart';

void main() {
  group('buildReportPlainText – estructura general', () {
    final date = DateTime(2025, 11, 14);

    final text = buildReportPlainText(
      date: date,
      block: 'Ciencia',
      name: 'María',
      title: 'Título de prueba',
      noticia: 'https://contraplano.cl/noticia',
      podcast: 'https://radio.cl/podcast',
      youtube: 'https://youtu.be/abc123',
      linkedin: 'https://linkedin.com/test',
      facebook: 'https://facebook.com/test',
      instagram: 'https://instagram.com/test',
      instagramStory: 'https://instagram.com/stories/test',
      tiktok1: 'https://tiktok.com/@test1',
      tiktok2: 'https://tiktok.com/@test2',
      x: 'https://x.com/test',
      newsletterImageUrl: 'https://cdn.cl/news.png',
      newsletterDesc: 'Texto newsletter',
      seoNoticiaUrl: 'https://cdn.cl/seo-noticia.png',
      seoPodcastUrl: 'https://cdn.cl/seo-podcast.png',
      rankMath: 90,
    );

    test('incluye encabezado correcto con fecha', () {
      expect(text.contains('Reporte 14-11-2025'), true);
    });

    test('incluye bloque en mayúsculas', () {
      expect(text.contains('BLOQUE:\nCIENCIA'), true);
    });

    test('incluye nombre', () {
      expect(text.contains('Nombre:\nMaría'), true);
    });

    test('incluye título', () {
      expect(text.contains('Título de la noticia:\nTítulo de prueba'), true);
    });

    test('incluye enlaces principales', () {
      expect(text.contains('Link Noticia Contraplano:'), true);
      expect(text.contains('https://contraplano.cl/noticia'), true);

      expect(text.contains('Link Podcast Contraplano:'), true);
      expect(text.contains('https://radio.cl/podcast'), true);
    });

    test('incluye redes sociales si existen', () {
      expect(text.contains('Youtube:'), true);
      expect(text.contains('LinkedIn:'), true);
      expect(text.contains('Facebook:'), true);
      expect(text.contains('Instagram:'), true);
      expect(text.contains('Instagram Story:'), true);
      expect(text.contains('Tiktok:'), true);
      expect(text.contains('Tiktok 2:'), true);
      expect(text.contains('Link X:'), true);
    });

    test('incluye SEO Noticia y SEO Podcast si existen', () {
      expect(text.contains('SEO Noticia (URL):'), true);
      expect(text.contains('seo-noticia.png'), true);

      expect(text.contains('SEO Podcast (URL):'), true);
      expect(text.contains('seo-podcast.png'), true);
    });

    test('incluye Rank Math si está dentro de rango', () {
      expect(text.contains('Rank Math SEO:\n90/100 (EXCELENTE)'), true);
    });

    test('NO incluye Rank Math si es null o inválido', () {
      final t = buildReportPlainText(
        date: DateTime(2025),
        block: 'A',
        name: 'B',
        title: 'C',
        noticia: 'url',
        podcast: 'url',
        rankMath: null,
      );
      expect(t.contains('Rank Math SEO'), false);
    });

    test('incluye sección del newsletter <article>', () {
      expect(text.contains('<article>'), true);
      expect(text.contains('<h2>Título de prueba</h2>'), true);
      expect(text.contains('href="https://contraplano.cl/noticia"'), true);
      expect(text.contains('src="https://cdn.cl/news.png"'), true);
      expect(text.contains('Texto newsletter'), true);
    });

    test('limpia saltos de línea excesivos (no más de 2 consecutivos)', () {
      // Dejamos un máximo permitido de dos \n consecutivos
      final tooMany = RegExp(r'\n{3,}').hasMatch(text);
      expect(tooMany, false);
    });
  });

  group('buildReportPlainText – opcionales', () {
    final base = {
      'date': DateTime(2025, 1, 1),
      'block': 'X',
      'name': 'Y',
      'title': 'Z',
      'noticia': 'url',
      'podcast': 'url',
    };

    test('no incluye Youtube si viene null', () {
      final t = buildReportPlainText(
        date: base['date'] as DateTime,
        block: 'X',
        name: 'Y',
        title: 'Z',
        noticia: 'url',
        podcast: 'url',
        youtube: null,
      );
      expect(t.contains('Youtube:'), false);
    });

    test('no incluye newsletter image si viene null', () {
      final t = buildReportPlainText(
        date: base['date'] as DateTime,
        block: 'X',
        name: 'Y',
        title: 'Z',
        noticia: 'url',
        podcast: 'url',
        newsletterImageUrl: null,
      );
      expect(t.contains('URL de la Imagen para Newsletter:'), false);
    });

    test('no incluye newsletter desc si viene null', () {
      final t = buildReportPlainText(
        date: base['date'] as DateTime,
        block: 'X',
        name: 'Y',
        title: 'Z',
        noticia: 'url',
        podcast: 'url',
        newsletterDesc: null,
      );
      expect(t.contains('Descripción para Newsletter:'), false);
    });
  });
}
