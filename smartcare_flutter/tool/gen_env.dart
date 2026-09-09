// Converte o .env da raiz do projeto em dart_defines.json, consumido por
// `flutter run --dart-define-from-file=dart_defines.json`.
//
// Uso: dart run tool/gen_env.dart
//
// Ambos os arquivos ficam fora do git.
import 'dart:convert';
import 'dart:io';

/// Chaves aceitas — precisam bater com os `String.fromEnvironment` do app.
const _knownKeys = {
  'GEMINI_API_KEY',
  'SMARTHAS_API_URL',
  'SMARTHAS_EMAIL',
  'SMARTHAS_PASSWORD',
};

void main() {
  final env = _readEnv(File('.env'));

  final unknown = env.keys.where((k) => !_knownKeys.contains(k));
  for (final key in unknown) {
    stderr.writeln('Aviso: $key nao e usada pelo app e sera ignorada.');
  }

  final defines = <String, String>{
    for (final key in _knownKeys)
      if ((env[key] ?? '').isNotEmpty) key: env[key]!,
  };

  File('dart_defines.json')
      .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(defines)}\n');

  if (defines.isEmpty) {
    stdout.writeln('dart_defines.json gerado vazio — o app roda em modo demonstracao.');
  } else {
    stdout.writeln('dart_defines.json gerado com: ${defines.keys.join(', ')}');
  }
}

Map<String, String> _readEnv(File file) {
  if (!file.existsSync()) {
    stderr.writeln('Erro: .env nao encontrado. Copie o .env.example para .env.');
    exit(1);
  }

  final values = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final separator = line.indexOf('=');
    if (separator == -1) continue;

    final key = line.substring(0, separator).trim();
    var value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}
