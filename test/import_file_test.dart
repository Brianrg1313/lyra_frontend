import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/import_file.dart';

void main() {
  group('a que endpoint va cada archivo', () {
    test('el CSV va por su rama y las planillas por la de Excel', () {
      expect(importFormatOf(r'C:\stock\lista.csv'), ImportFormat.csv);
      expect(importFormatOf(r'C:\stock\lista.xlsx'), ImportFormat.excel);
      expect(importFormatOf(r'C:\stock\lista.xls'), ImportFormat.excel);
      expect(importFormatOf(r'C:\stock\lista.ods'), ImportFormat.excel);
    });

    test('la extension se mira sin distinguir mayusculas', () {
      expect(importFormatOf('/home/lista.CSV'), ImportFormat.csv);
      expect(importFormatOf('/home/lista.XLSX'), ImportFormat.excel);
    });

    test('lo que no es planilla ni CSV no se sube', () {
      // El dialogo del sistema ya filtra, pero en Linux y macOS el nombre se
      // puede escribir a mano y saltearse ese filtro.
      expect(importFormatOf('/home/lista.pdf'), isNull);
      expect(importFormatOf('/home/lista'), isNull);
      expect(importFormatOf('/home/lista.'), isNull);
      expect(importFormatOf('/home/.csv'), isNull);
    });

    test('un punto en la carpeta no se confunde con la extension', () {
      expect(importFormatOf(r'C:\v1.0\stock'), isNull);
    });
  });

  group('el nombre con el que nace la tabla', () {
    test('es el del archivo sin extension, con cualquier separador', () {
      expect(importTableName(r'C:\stock\Lista de precios.xlsx'),
        'Lista de precios');
      expect(importTableName('/home/user/Lista de precios.csv'),
        'Lista de precios');
    });

    test('solo se saca la ultima extension', () {
      expect(importTableName('/home/copia.2024.xlsx'), 'copia.2024');
    });

    test('sin carpeta ni extension, es el nombre tal cual', () {
      expect(importTableName('lista'), 'lista');
    });

    test('queda vacio si no hay nombre, y ahi el backend pone el suyo', () {
      expect(importTableName('/home/.csv'), '');
      expect(importTableName(r'C:\stock\   .xlsx'), '');
    });
  });

  test('las extensiones que se ofrecen son las que se saben leer', () {
    for (final extension in kImportExtensions) {
      expect(importFormatOf('lista.$extension'), isNotNull,
        reason: 'el dialogo ofrece .$extension pero no se sabe a donde subirlo');
      expect(extension.startsWith('.'), isFalse,
        reason: 'el dialogo del sistema pide las extensiones sin punto');
    }
  });
}
