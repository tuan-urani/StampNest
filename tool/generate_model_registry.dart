import 'dart:io';

void main() {
  final projectRoot = Directory.current.path;
  final modelRoot =
      Directory('$projectRoot/lib/src/core/model'); // absolute at runtime

  final uiDomainFiles = <File>[];
  final requestFiles = <File>[];
  final responseFiles = <File>[];

  if (!modelRoot.existsSync()) {
    stderr.writeln('Model root not found: ${modelRoot.path}');
    exit(1);
  }

  // Collect files
  for (final entity in modelRoot.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final p = entity.path;
      if (p.contains('/request/')) {
        requestFiles.add(entity);
      } else if (p.contains('/response/')) {
        responseFiles.add(entity);
      } else {
        uiDomainFiles.add(entity);
      }
    }
  }

  String relPath(File f) =>
      f.path.replaceFirst(projectRoot, '').replaceFirst(RegExp(r'^/'), '');

  List<_Decl> parseDecls(File file) {
    final lines = file.readAsLinesSync();
    final decls = <_Decl>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final classMatch = RegExp(r'^class\s+([A-Za-z0-9_]+)').firstMatch(line);
      final enumMatch = RegExp(r'^enum\s+([A-Za-z0-9_]+)').firstMatch(line);
      if (classMatch != null || enumMatch != null) {
        final kind = classMatch != null ? 'class' : 'enum';
        final name = (classMatch ?? enumMatch)!.group(1)!;
        // Collect preceding doc comments (/// ...)
        final docLines = <String>[];
        var j = i - 1;
        while (j >= 0) {
          final prev = lines[j].trim();
          if (prev.startsWith('///')) {
            docLines.insert(0, prev.replaceFirst('///', '').trim());
            j--;
            continue;
          }
          break;
        }
        final description = docLines.isEmpty ? null : docLines.join(' ');
        decls.add(_Decl(kind, name, description));
      }
    }
    return decls;
  }

  String section(String title, List<File> files) {
    final b = StringBuffer('## $title\n\n');
    if (files.isEmpty) {
      b.writeln('- (none)\n');
      return b.toString();
    }
    for (final f in files) {
      final decls = parseDecls(f);
      final path = relPath(f);
      if (decls.isEmpty) {
        b.writeln('- $path');
      } else {
        for (final d in decls) {
          b.writeln('- ${d.kind} ${d.name} — $path');
          if (d.description != null && d.description!.isNotEmpty) {
            b.writeln('  - ${d.description}');
          }
        }
      }
    }
    b.writeln();
    return b.toString();
  }

  final out = StringBuffer()
    ..writeln('# Model Registry (AUTO-GENERATED)\n')
    ..writeln(
        '> Do not edit manually. Run: dart run tool/generate_model_registry.dart\n')
    ..writeln(section('UI/Domain Models', uiDomainFiles))
    ..writeln(section('Request Models', requestFiles))
    ..writeln(section('Response Models', responseFiles));

  // Ensure spec directory exists
  final specDir = Directory('$projectRoot/spec');
  if (!specDir.existsSync()) {
    specDir.createSync(recursive: true);
  }
  final outputFile =
      File('${specDir.path}/model-registry.md'); // overwrite existing
  outputFile.writeAsStringSync(out.toString());
  stdout.writeln('Generated ${outputFile.path}');
}

class _Decl {
  final String kind;
  final String name;
  final String? description;
  _Decl(this.kind, this.name, this.description);
}
