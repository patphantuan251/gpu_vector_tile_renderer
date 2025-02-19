final _snakeCaseRegex = RegExp(r'(?<=[a-z])[A-Z]');

/// Converts a given string to snake case.
String toSnakeCase(String str) {
  // Spaces are replaced with underscores
  // Uppercase letters are replaced with lowercase letters preceded by an underscore
  return str.replaceAll(' ', '_').replaceAllMapped(_snakeCaseRegex, (match) => '_${match.group(0)}').toLowerCase();
}

/// Converts a given snake_case string to upper camel case, which is suitable to use as a class name in Dart.
String nameToDartClassName(String name) {
  // a_b_c -> ABC
  final parts = name.split('_');
  return parts.map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join();
}

/// Converts a given snake_case string to lower camel case, which is suitable to use as a field name in Dart.
String nameToDartFieldName(String name) {
  // a_b_c -> aBC
  final parts = name.split('_');
  final first = parts.first[0].toLowerCase() + parts.first.substring(1);
  final rest = parts.skip(1).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join();
  return '$first$rest';
}