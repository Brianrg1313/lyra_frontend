import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/picture_import_model.dart';
import 'package:app/services/inventory/picture_key.dart';

/// The device's half of the pictures an import names (`PictureImportService`): the key a file
/// is matched by must equal the backend's `Ingest.key` (a key computed differently is a
/// picture that sits in the folder and is never sent), only pictures are delivered, and the
/// counters and lists read as `…/status` and `image/progress` send them.
void main() {
  group('the key a file name is matched by (Ingest.key)', () {
    test('case, accents, separators, the extension and the folder do not count', () {
      expect(pictureKey(r"fotos\AirForce One-White.PNG"), "airforceonewhite");
      expect(pictureKey("airforceone_white.jpg"), "airforceonewhite");
      expect(pictureKey("catálogo/Camión Rojo.jpeg"), "camionrojo");
      expect(pictureKey("PIÑA.webp"), "pina");
    });

    test('only an extension of 2 to 5 letters or digits is dropped', () {
      expect(pictureKey("modelo.2024"), "modelo");
      expect(pictureKey("modelo.v1.backup"), "modelov1backup");
    });

    test('a name with nothing to match by is empty', () {
      expect(pictureKey("---.png"), "");
      expect(pictureKey(""), "");
    });
  });

  test('a picture name ends in a picture extension', () {
    expect(isPictureName("af1.JPG"), isTrue);
    expect(isPictureName("foto.heic"), isTrue);
    expect(isPictureName("lista.xlsx"), isFalse);
    expect(isPictureName("sin foto"), isFalse);
  });

  test('only bytes that start like a picture are delivered', () {
    expect(looksLikePicture(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), isTrue);
    expect(looksLikePicture(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D])), isTrue);
    expect(looksLikePicture(Uint8List.fromList("RIFF\x00\x00\x00\x00WEBPVP8".codeUnits)), isTrue);
    // A host that refuses often answers 200 with a page.
    expect(looksLikePicture(Uint8List.fromList("<!DOCTYPE html>".codeUnits)), isFalse);
    expect(looksLikePicture(Uint8List(0)), isFalse);
  });

  group('what the backend says', () {
    test('image/progress: the counters and the tables whose rows changed', () {
      final progress = PictureProgress.fromJson({
        "tables": ["t1", "t2"],
        "server": 3,
        "client": "2",
        "files": 5,
        "failed": 1
      });

      expect(progress.downloading, 5);
      expect(progress.files, 5);
      expect(progress.failed, 1);
      expect(progress.tables, ["t1", "t2"]);
      expect(progress.isIdle, isFalse);
      expect(PictureProgress.fromJson(null).isIdle, isTrue);
    });

    test('status: the missing names and the failures, compressed', () {
      final status = PictureImportStatus.fromResponse({
        "server": 0,
        "client": 0,
        "files": 2,
        "failed": 1,
        "names": ["af1.png", "", "camión.jpg"],
        "failures": {
          "keys": ["id", "value", "reason"],
          "values": [["j1", "https://shop.test/a.jpg", "client: http 404"]]
        }
      });

      expect(status.progress.files, 2);
      expect(status.names, ["af1.png", "camión.jpg"]);
      expect(status.failures.single.id, "j1");
      expect(status.failures.single.value, "https://shop.test/a.jpg");
      expect(status.failures.single.reason, "client: http 404");
    });
  });
}
