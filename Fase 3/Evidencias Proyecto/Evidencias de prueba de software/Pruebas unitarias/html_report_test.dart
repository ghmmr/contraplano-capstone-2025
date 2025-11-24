import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/html_report.dart';

void main() {
  group('buildReportHtml – estructura base', () {
    final date = DateTime(2025, 11, 14);

    final html = buildReportHtml(
      date: date,
      block: "Ciencia",
      name: "María",
      title: "Título de prueba",
      noticia: "https://contraplano.cl/noticia",
      podcast: "https://radio.cl/podcast",
      youtube: "https://youtu.be/abc123",
      linkedin: "https://linkedin.com/test",
      facebook: "https://facebook.com/test",
      instagram: "https://instagram.com/test",
      instagramStory: "https://instagram.com/stories/test",
      tiktok1: "https://tiktok.com/@test1",
      tiktok2: "https://tiktok.com/@test2",
      x: "https://x.com/test",
      seoNoticiaUrl: "https://cdn.cl/seo-noticia.png",
      seoPodcastUrl: "https://cdn.cl/seo-podcast.png",
      newsletterImageUrl: "https://cdn.cl/news.png",
      newsletterDesc: "Imagen newsletter",
      rankMath: 90,
    );

    test('contiene doctype y estructura HTML básica', () {
      expect(html.contains('<!doctype html>'), true);
      expect(html.contains('<html lang="es">'), true);
      expect(html.contains('<head>'), true);
      expect(html.contains('<body>'), true);
      expect(html.contains('</html>'), true);
    });

    test('incluye título en <h1>', () {
      expect(html.contains('<h1>Título de prueba</h1>'), true);
    });

    test('incluye header con fecha, bloque y autor', () {
      expect(
        html.contains('2025-11-14 • Bloque: <strong>Ciencia</strong> • Autor: María'),
        true,
      );
    });

    test('incluye la lista principal <ul> con cierre correcto', () {
      expect(html.contains('<ul>'), true);
      expect(html.contains('</ul>'), true);
    });

    test('incluye los enlaces principales en el orden correcto', () {
      final expectedOrder = [
        'Noticia',
        'Podcast',
        'YouTube',
        'LinkedIn',
        'Facebook',
        'Instagram',
        'Instagram Story',
        'TikTok 1',
        'TikTok 2',
        'X',
        'SEO Noticia',
        'SEO Podcast',
      ];

      int lastIndex = -1;
      for (final label in expectedOrder) {
        final currentIndex = html.indexOf('<li><strong>$label:</strong>');
        expect(currentIndex > lastIndex, true,
            reason: 'El elemento "$label" no está en el orden correcto.');
        lastIndex = currentIndex;
      }
    });

    test('los enlaces se renderizan como <a href="...">', () {
      expect(html.contains('<a href="https://contraplano.cl/noticia"'), true);
      expect(html.contains('<a href="https://radio.cl/podcast"'), true);
      expect(html.contains('<a href="https://youtu.be/abc123"'), true);
    });

    test('no repite Noticia ni Podcast en la lista principal', () {
  final noticiaCount =
      RegExp(r'<li><strong>Noticia:</strong>').allMatches(html).length;

  final podcastCount =
      RegExp(r'<li><strong>Podcast:</strong>').allMatches(html).length;

  expect(noticiaCount, 1);
  expect(podcastCount, 1);
});
  });

  group('buildReportHtml – Rank Math', () {
    test('se muestra si rankMath es válido (>=1 y <=100)', () {
      final html = buildReportHtml(
        date: DateTime(2025),
        block: "A",
        name: "B",
        title: "C",
        noticia: "url",
        podcast: "url",
        rankMath: 85,
      );

      expect(html.contains('Rank Math SEO:</strong> 85/100'), true);
    });

    test('no se muestra si rankMath es null o inválido', () {
      final html = buildReportHtml(
        date: DateTime(2025),
        block: "A",
        name: "B",
        title: "C",
        noticia: "url",
        podcast: "url",
        rankMath: null,
      );

      expect(html.contains('Rank Math SEO'), false);
    });
  });

  group('buildReportHtml – imágenes SEO y Newsletter', () {
    final baseParams = {
      'date': DateTime(2025, 1, 1),
      'block': "A",
      'name': "B",
      'title': "C",
      'noticia': "url",
      'podcast': "url",
    };

    test('incluye imagen de Newsletter si viene URL', () {
      final html = buildReportHtml(
        date: baseParams['date'] as DateTime,
        block: "A",
        name: "B",
        title: "C",
        noticia: "url",
        podcast: "url",
        newsletterImageUrl: "https://img.com/test.png",
        newsletterDesc: "Descripción",
      );

      expect(html.contains('Imagen Newsletter'), true);
      expect(html.contains('<img src="https://img.com/test.png"'), true);
      expect(html.contains('Descripción'), true);
    });

    test('incluye SEO noticia si viene URL', () {
      final html = buildReportHtml(
        date: baseParams['date'] as DateTime,
        block: "A",
        name: "B",
        title: "C",
        noticia: "url",
        podcast: "url",
        seoNoticiaUrl: "https://cdn.cl/seo-not.png",
      );

      expect(html.contains('SEO noticia'), true);
      expect(html.contains('src="https://cdn.cl/seo-not.png"'), true);
    });

    test('incluye SEO podcast si viene URL', () {
      final html = buildReportHtml(
        date: baseParams['date'] as DateTime,
        block: "A",
        name: "B",
        title: "C",
        noticia: "url",
        podcast: "url",
        seoPodcastUrl: "https://cdn.cl/seo-pod.png",
      );

      expect(html.contains('SEO podcast'), true);
      expect(html.contains('src="https://cdn.cl/seo-pod.png"'), true);
    });
  });
}
