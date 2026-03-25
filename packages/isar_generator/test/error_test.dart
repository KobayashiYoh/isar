import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_generator/isar_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Error case', () {
    for (final file in Directory('test/errors').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      test(file.path, () async {
        final content = await file.readAsLines();

        final errorMessage = content.first.split('//').last.trim();

        // Load isar package files for the test
        const isarLibPath = '../isar/lib';
        final isarFiles = <String, String>{};

        // Add main isar.dart file
        final isarDart = File('$isarLibPath/isar.dart');
        if (isarDart.existsSync()) {
          isarFiles['isar|lib/isar.dart'] = await isarDart.readAsString();
        }

        // Add annotation files
        final annotationsDir = Directory('$isarLibPath/src/annotations');
        if (annotationsDir.existsSync()) {
          await for (final entity in annotationsDir.list()) {
            if (entity is File && entity.path.endsWith('.dart')) {
              final relativePath = entity.path.replaceFirst(
                '$isarLibPath/',
                '',
              );
              isarFiles['isar|lib/$relativePath'] = await entity.readAsString();
            }
          }
        }

        // Add isar_link.dart for IsarLink and IsarLinks definitions
        final isarLinkFile = File('$isarLibPath/src/isar_link.dart');
        if (isarLinkFile.existsSync()) {
          isarFiles['isar|lib/src/isar_link.dart'] = await isarLinkFile
              .readAsString();
        }

        // Add meta package files (required for @Target, @protected annotations)
        final metaFiles = {
          'meta|lib/meta.dart': "library meta;\n\nexport 'src/meta.dart';",
          'meta|lib/src/meta.dart': '''
library meta.dart;

class Target {
  final Set<TargetKind> kinds;
  const Target(this.kinds);
}

enum TargetKind {
  classType,
  enumType,
  extension,
  field,
  function,
  library,
  method,
  mixinType,
  parameter,
  type,
  typedefType,
}

class _Protected {
  const _Protected();
}

const protected = _Protected();

class _Immutable {
  const _Immutable();
}

const immutable = _Immutable();
''',
          'meta|lib/meta_meta.dart': '''
library meta_meta;

export 'src/meta.dart' show Target, TargetKind;
''',
        };
        isarFiles.addAll(metaFiles);

        final result = await testBuilder(
          getIsarGenerator(BuilderOptions.empty),
          {'a|${file.path}': content.join('\n'), ...isarFiles},
        );

        final error = result.errors.join('\n');
        expect(error.toLowerCase(), contains(errorMessage.toLowerCase()));
      });
    }
  });
}
