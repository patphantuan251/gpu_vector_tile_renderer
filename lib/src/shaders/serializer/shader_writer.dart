import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';
import 'package:vector_math/vector_math_64.dart';

/// Writes a shader to a string.
String writeShader(ParsedShader shader) {
  final buffer = StringBuffer();

  int currentIndent = 0;
  for (final content in shader.content) {
    if (content is String && content.startsWith('}')) currentIndent--;

    String line;

    if (content is ShaderPragma) {
      line = _writePragma(content);
    } else if (content is ShaderUbo) {
      line = _writeUbo(content);
    } else if (content is ShaderVariable) {
      line = _writeVariable(content);
    } else if (content is ShaderUniformSampler) {
      line = _writeUniformSampler(content);
    } else {
      line = content.toString();
    }

    if (line.trimLeft().length == line.length) {
      line = '  ' * currentIndent + line.trimLeft();
    }
    
    buffer.writeln(line);
    if (content is String && content.endsWith('{')) currentIndent++;
  }

  // Remove duplicated newlines
  return buffer.toString().replaceAll(RegExp(r'\n\n\n+'), '\n\n');
}

String _writePragma(ShaderPragma pragma) {
  return '#pragma ${pragma.value}';
}

String _writeUniformSampler(ShaderUniformSampler sampler) {
  return 'uniform sampler2D ${sampler.name};';
}

String _writeUbo(ShaderUbo ubo) {
  final buffer = StringBuffer();

  buffer.writeln('uniform ${ubo.name} {');

  for (final variable in ubo.variables) {
    buffer.writeln('  ${_writeVariable(variable)}');
  }

  buffer.writeln('} ${ubo.instanceName};');

  return buffer.toString();
}

String _writeVariable(ShaderVariable variable) {
  final buffer = StringBuffer();

  if (variable.qualifier != null) buffer.write('${variable.qualifier!.value} ');
  if (variable.precision != null) buffer.write('${variable.precision!.value} ');
  buffer.write('${variable.typeGlsl.value} ${variable.name}');

  if (variable.value != null) {
    buffer.write(' = ');
    buffer.write(_writeVariableValue(variable));
  }

  buffer.write(';');

  return buffer.toString();
}

String _writeVariableValue(ShaderVariable variable) {
  final value = variable.value!;
  if (value is String) return value;

  if (variable.typeGlsl == ShaderGlslType.bool) {
    if (value is bool) return value.toString();
    throw ArgumentError('Invalid value for bool: $value');
  } else if (variable.typeGlsl == ShaderGlslType.float) {
    if (value is num) return value.toString();
    throw ArgumentError('Invalid value for float: $value');
  } else if (variable.typeGlsl == ShaderGlslType.int_) {
    if (value is int) return value.toString();
    throw ArgumentError('Invalid value for int: $value');
  } else if (variable.typeGlsl == ShaderGlslType.mat2) {
    if (value is Matrix2) return 'mat2(${value.storage.join(', ')})';
    if (value is List && value.length == 4) return 'mat2(${value.join(', ')})';
    throw ArgumentError('Invalid value for mat2: $value');
  } else if (variable.typeGlsl == ShaderGlslType.mat3) {
    if (value is Matrix3) return 'mat3(${value.storage.join(', ')})';
    if (value is List && value.length == 9) return 'mat3(${value.join(', ')})';
    throw ArgumentError('Invalid value for mat3: $value');
  } else if (variable.typeGlsl == ShaderGlslType.mat4) {
    if (value is Matrix4) return 'mat4(${value.storage.join(', ')})';
    if (value is List && value.length == 16) return 'mat4(${value.join(', ')})';
    throw ArgumentError('Invalid value for mat4: $value');
  } else if (variable.typeGlsl == ShaderGlslType.vec2) {
    if (value is Vector2) return 'vec2(${value.storage.join(', ')})';
    if (value is List && value.length == 2) return 'vec2(${value.join(', ')})';
    throw ArgumentError('Invalid value for vec2: $value');
  } else if (variable.typeGlsl == ShaderGlslType.vec3) {
    if (value is Vector3) return 'vec3(${value.storage.join(', ')})';
    if (value is List && value.length == 3) return 'vec3(${value.join(', ')})';
    throw ArgumentError('Invalid value for vec3: $value');
  } else if (variable.typeGlsl == ShaderGlslType.vec4) {
    if (value is Vector4) return 'vec4(${value.storage.join(', ')})';
    if (value is List && value.length == 4) return 'vec4(${value.join(', ')})';
    throw ArgumentError('Invalid value for vec4: $value');
  } else if (variable.typeGlsl == ShaderGlslType.sampler2D) {
    throw UnimplementedError('Sampler2D serialization not implemented');
  }

  throw UnimplementedError('Value serialization not implemented for ${variable.typeGlsl}');
}
