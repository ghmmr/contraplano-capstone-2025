// test/utils/image_tools_test.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrc_contraplano/utils/image_tools.dart';
import 'package:image/image.dart' as img;

void main() {
  group('compressToJpegBase64 - comportamiento general', () {
    test('retorna input si no es una imagen válida', () {
      final invalid = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = compressToJpegBase64(invalid);

      expect(result.bytes, invalid);
      expect(result.base64Jpg, base64Encode(invalid));
    });

    test('procesa y comprime una imagen PNG válida', () {
      // Creamos una imagen de prueba 100x100 píxeles
      final image = img.Image(width: 100, height: 100);
      final pngBytes = Uint8List.fromList(img.encodePng(image));

      final result = compressToJpegBase64(pngBytes);

      // Debe generar un JPG (más pequeño que PNG)
      expect(result.bytes.isNotEmpty, true);
      expect(result.base64Jpg.isNotEmpty, true);

      // Debe ser un JPG válido
      expect(result.bytes[0] == 0xFF && result.bytes[1] == 0xD8, true,
          reason: "Debe comenzar con firma JPG (FFD8)");
    });

    test('respeta el límite de resize: si mide más de 1600px se reduce', () {
      // Imagen artificial muy grande de 3000px de ancho
      final bigImage = img.Image(width: 3000, height: 1000);
      final pngBytes = Uint8List.fromList(img.encodePng(bigImage));

      final result = compressToJpegBase64(pngBytes);

      final decodedJpg = img.decodeImage(result.bytes)!;

      expect(decodedJpg.width, 1600); // 🔥 clave del test
    });

    test('no reduce imágenes pequeñas (menos de 1600px)', () {
      final small = img.Image(width: 800, height: 600);
      final pngBytes = Uint8List.fromList(img.encodePng(small));

      final result = compressToJpegBase64(pngBytes);

      final decoded = img.decodeImage(result.bytes)!;

      expect(decoded.width, 800);
      expect(decoded.height, 600);
    });

    test('la salida base64 corresponde a los bytes devueltos', () {
      final image = img.Image(width: 200, height: 200);
      final pngBytes = Uint8List.fromList(img.encodePng(image));

      final result = compressToJpegBase64(pngBytes);

      final b64 = base64Encode(result.bytes);

      expect(result.base64Jpg, b64);
    });
  });
}
