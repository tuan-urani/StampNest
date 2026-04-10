import 'dart:io';

void main() {
  final projectRoot = Directory.current.path;
  final uiRoot = Directory('$projectRoot/lib/src/ui');
  if (!uiRoot.existsSync()) {
    stderr.writeln('UI root not found: ${uiRoot.path}');
    exit(1);
  }

  final specDir = Directory('$projectRoot/spec');
  if (!specDir.existsSync()) {
    specDir.createSync(recursive: true);
  }
  final outputFile = File('${specDir.path}/ui-workflow.md');

  final sections = <String>[];
  for (final featureDir in uiRoot.listSync()) {
    if (featureDir is! Directory) continue;
    final name = featureDir.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => featureDir.path.split('/').last,
    );

    final pages = <_FileDoc>[];
    final components = <_FileDoc>[];
    final hasBinding = Directory('${featureDir.path}/binding').existsSync();
    final hasInteractor =
        Directory('${featureDir.path}/interactor').existsSync();
    final interactorFiles =
        Directory('${featureDir.path}/interactor').existsSync()
            ? Directory('${featureDir.path}/interactor')
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))
                .toList()
            : <File>[];

    // Collect page and component files
    for (final entity in featureDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final rel = entity.path
            .replaceFirst(projectRoot, '')
            .replaceFirst(RegExp(r'^/'), '');
        if (entity.path.endsWith('_page.dart')) {
          pages.add(_readDoc(entity, rel));
        } else if (rel.contains('/components/')) {
          components.add(_readDoc(entity, rel));
        }
      }
    }

    // Derive feature goal from the first page doc (if any)
    final featureGoal =
        pages.isNotEmpty && pages.first.description != null
            ? pages.first.description!
            : '';

    final b =
        StringBuffer()
          ..writeln('## $name')
          ..writeln('**Path**: lib/src/ui/$name\n')
          ..writeln('### 1. Description')
          ..writeln('Goal: ${featureGoal.isEmpty ? "" : featureGoal}')
          ..writeln('Features:')
          ..writeln('- ')
          ..writeln('\n### 2. UI Structure')
          ..writeln('- Screens:')
          ..writeAll(
            pages.map(
              (p) =>
                  '  - ${p.symbolName} — ${p.relPath}\n${p.description != null && p.description!.isNotEmpty ? '    - ${p.description!}\n' : ''}',
            ),
          )
          ..writeln('- Components:')
          ..writeAll(
            components.map(
              (c) =>
                  '  - ${c.symbolName} — ${c.relPath}\n${c.description != null && c.description!.isNotEmpty ? '    - ${c.description!}\n' : ''}',
            ),
          )
          ..writeln('\n### 3. User Flow & Logic')
          ..writeln('1) ')
          ..writeln('2) ')
          ..writeln('\n### 4. Key Dependencies')
          ..writeln(hasInteractor ? '- interactor/*' : '- (none)')
          ..writeAll(
            interactorFiles.map(
              (f) =>
                  '  - ${f.path.replaceFirst(projectRoot, '').replaceFirst(RegExp(r'^/'), '')}\n',
            ),
          )
          ..writeln(hasBinding ? '- binding/*' : '- (none)')
          ..writeln('\n### 5. Notes & Known Issues')
          ..writeln('- ')
          ..writeln('');

    sections.add(b.toString());
  }

  final out =
      StringBuffer()
        ..writeln('# UI Workflow (AUTO-GENERATED)\n')
        ..writeln(
          '> Do not edit manually. Run: dart run tool/generate_ui_workflow_spec.dart\n',
        )
        ..writeAll(sections);

  outputFile.writeAsStringSync(out.toString());
  stdout.writeln('Generated ${outputFile.path}');
}

class _FileDoc {
  final String relPath;
  final String symbolName;
  final String? description;
  _FileDoc(this.relPath, this.symbolName, this.description);
}

_FileDoc _readDoc(File file, String relPath) {
  final lines = file.readAsLinesSync();
  String? symbolName;
  String? description;

  // Find first class or widget name
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    final classMatch = RegExp(r'^class\s+([A-Za-z0-9_]+)').firstMatch(line);
    if (classMatch != null) {
      symbolName = classMatch.group(1)!;
      // Collect leading doc comments (/// ...) before class
      final docLines = <String>[];
      var j = i - 1;
      while (j >= 0) {
        final prev = lines[j].trim();
        if (prev.startsWith('///')) {
          docLines.insert(0, prev.replaceFirst('///', '').trim());
          j--;
          continue;
        }
        // Stop at non-doc line
        break;
      }
      if (docLines.isNotEmpty) {
        description = docLines.join(' ');
      }
      break;
    }
  }

  // Fallback: top-of-file doc block
  if (description == null) {
    final docLines = <String>[];
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('///')) {
        docLines.add(t.replaceFirst('///', '').trim());
      } else if (t.isEmpty || t.startsWith('//')) {
        // continue scanning
        continue;
      } else {
        break;
      }
    }
    if (docLines.isNotEmpty) {
      description = docLines.join(' ');
    }
  }

  // Fallback symbol name to file basename
  symbolName ??= relPath.split('/').last.replaceAll('.dart', '');
  return _FileDoc(relPath, symbolName, description);
}
