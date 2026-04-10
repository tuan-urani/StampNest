import 'dart:io';

void main() {
  final code1 = _runWithFallback('tool/generate_model_registry.dart');
  if (code1 != 0) exit(code1);
  final code2 = _runWithFallback('tool/generate_ui_workflow_spec.dart');
  if (code2 != 0) exit(code2);
}

int _runWithFallback(String scriptPath) {
  const runners = <List<String>>[
    <String>['dart', 'run'],
    <String>['fvm', 'dart', 'run'],
    <String>['flutter', 'pub', 'run'],
  ];

  ProcessResult? lastResult;
  for (final runner in runners) {
    final command = runner.first;
    final args = <String>[...runner.sublist(1), scriptPath];
    final result = Process.runSync(command, args, runInShell: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      return 0;
    }
    if (!_isCommandNotFound(result)) {
      return result.exitCode;
    }
    lastResult = result;
  }

  return lastResult?.exitCode ?? 1;
}

bool _isCommandNotFound(ProcessResult result) {
  if (result.exitCode == 127) return true;
  final stderrText = '${result.stderr}'.toLowerCase();
  return stderrText.contains('command not found') || stderrText.contains('is not recognized');
}
