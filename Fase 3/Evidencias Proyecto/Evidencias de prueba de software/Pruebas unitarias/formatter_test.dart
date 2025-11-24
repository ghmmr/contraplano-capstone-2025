import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/formatter.dart';

void main() {

  // =============================
  //  prettyBlock()
  // =============================
  group('prettyBlock', () {
    test('capitaliza una palabra', () {
      expect(prettyBlock("noticias"), "Noticias");
    });

    test('capitaliza múltiples palabras', () {
      expect(prettyBlock("region metropolitana"), "Region Metropolitana");
    });

    test('maneja strings vacíos', () {
      expect(prettyBlock(""), "");
    });
  });

  // =============================
  //  blockComment()
  // =============================
  group('blockComment', () {
    test('convierte bloque a comentario HTML en minúsculas', () {
      expect(blockComment("Noticias"), "<!-- noticias -->");
    });
  });

  // =============================
  //  formatReportClipboard()
  // =============================
  group('formatReportClipboard', () {
    test('incluye título, nombre y bloque correctamente', () {
      final result = formatReportClipboard(
        date: DateTime(2025, 1, 1),
        block: "noticias regionales",
        name: "Francisco",
        title: "Corte Suprema aprueba recurso",
        noticia: "https://x.cl/not",
        podcast: "https://x.cl/pod",
      );

      expect(result.contains("Reporte 01-01-2025"), true);
      expect(result.contains("Francisco"), true);
      expect(result.contains("Corte Suprema aprueba recurso"), true);
      expect(result.contains("Noticias Regionales"), true); // prettyBlock()
    });

    test('campos vacíos se formatean pero no explotan', () {
      final result = formatReportClipboard(
        date: DateTime(2025, 1, 1),
        block: "noticias",
        name: "Ana",
        title: "Algo pasó",
      );

      // Sigue existiendo la etiqueta pero valor vacío
      expect(result.contains("Link Noticia Contraplano:"), true);
      expect(result.contains("Link Podcast Contraplano:"), true);
    });

    test('incluye correctamente el HTML para newsletter', () {
      final result = formatReportClipboard(
        date: DateTime(2025, 1, 1),
        block: "Noticias",
        name: "Ana",
        title: "Algo pasó",
        noticia: "https://x.cl/not",
        newsletterImageUrl: "https://img.cl/foto.png",
        newsletterDesc: "Descripción breve",
      );

      expect(result.contains("<article>"), true);
      expect(result.contains("<h2>Algo pasó</h2>"), true);
      expect(result.contains('img src="https://img.cl/foto.png"'), true);
      expect(result.contains("Descripción breve"), true);
    });

    test('si no hay noticia, igual genera el HTML sin enlaces', () {
      final result = formatReportClipboard(
        date: DateTime(2025, 1, 1),
        block: "Noticias",
        name: "Ana",
        title: "Algo pasó",
      );

      // HTML básico sin <a>
      expect(result.contains("<article>"), true);
      expect(result.contains("<h2>Algo pasó</h2>"), true);
      expect(result.contains("Continuar leyendo"), false); // porque no hay noticia
    });
  });
}
