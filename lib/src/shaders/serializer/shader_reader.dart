import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';

// UBOS:
// uniform {name} {
//  {type} {name};
//  ...
// } {name};

final _uboStartRegex = RegExp(r'uniform\s+\w+\s+\{');
final _whitespace = RegExp(r'\s+');

// (in|out)? (highp|mediump|lowp)? (\w+) (\w+);
final _variableRegex = RegExp(r'(in|out)?\s*(highp|mediump|lowp)?\s*(\w+)\s+(\w+)\;');

/// Parses a shader from a string.
///
/// See [ParsedShader] on how to use the parsed shader.
ParsedShader readShader(String source, {required String name, required ShaderType type}) {
  final content = <Object>[];

  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineTrim = line.trim();

    if (lineTrim.startsWith('#pragma')) {
      content.add(_readPragma(lineTrim));
    } else if (lineTrim.startsWith(_uboStartRegex)) {
      final parts = lineTrim.split(_whitespace);
      final uboName = parts[1];
      String? instanceName;

      final variables = <ShaderVariable>[];

      var j = i + 1;
      for (; j < lines.length; j++) {
        final uboLine = lines[j].trim();

        if (uboLine.startsWith('}')) {
          instanceName = uboLine.split(_whitespace).last.split(';').first;
          break;
        }

        variables.add(_readShaderVariable(uboLine));
      }

      if (instanceName != null) {
        content.add(ShaderUbo(name: uboName, instanceName: instanceName, variables: variables));
        i = j;
      }
      else {
        content.add(line);
      }
    } else if (!line.startsWith(_whitespace) && _variableRegex.hasMatch(line)) {
      if (line.startsWith('precision')) {
        content.add(line);
      } else {
        // Attributes can only be in the non-indented lines
        content.add(_readShaderVariable(line));
      }
    } else {
      content.add(line);
    }
  }

  if (type == ShaderType.vertex) {
    return ParsedShaderVertex(name: name, type: type, content: content);
  } else if (type == ShaderType.fragment) {
    return ParsedShaderFragment(name: name, type: type, content: content);
  } else {
    throw UnimplementedError('Shader type not supported: $type');
  }
}

ShaderPragma _readPragma(String line) {
  assert(line.startsWith('#pragma'));

  final value = line.substring('#pragma'.length).trim();
  if (!value.contains(':')) return ShaderPragma(value: value);

  final parts = value.split(':').map((e) => e.trim()).toList();
  final name = parts[0];

  if (name == 'prelude') {
    return PreludeShaderPragma(name: parts[1], value: value);
  }

  if (name == 'prop') {
    final propFunctionName = parts[1].split('(').first;
    final propFunctionArgs = parts[1].split('(').last.split(')').first.split(',').map((e) => e.trim()).toList();

    if (propFunctionName == 'resolve') {
      return PropResolutionShaderPragma(resolutions: propFunctionArgs, value: value);
    } else if (propFunctionName == 'declare') {
      return PropDeclarationShaderPragma(variable: _readShaderVariable(propFunctionArgs[0]), value: value);
    }
  }

  return ShaderPragma(value: value);
}

ShaderVariableQualifier _readShaderVariableQualifier(String qualifier) {
  return switch (qualifier) {
    'in' => ShaderVariableQualifier.in_,
    'out' => ShaderVariableQualifier.out_,
    'const' => ShaderVariableQualifier.const_,
    _ => throw UnimplementedError('Qualifier not supported: $qualifier'),
  };
}

ShaderVariablePrecision _readShaderVariablePrecision(String precision) {
  return switch (precision) {
    'highp' => ShaderVariablePrecision.highp,
    'mediump' => ShaderVariablePrecision.mediump,
    'lowp' => ShaderVariablePrecision.lowp,
    _ => throw UnimplementedError('Precision not supported: $precision'),
  };
}

ShaderGlslType _readShaderGlslType(String type) {
  return switch (type) {
    'float' => ShaderGlslType.float,
    'int' => ShaderGlslType.int_,
    'vec2' => ShaderGlslType.vec2,
    'vec3' => ShaderGlslType.vec3,
    'vec4' => ShaderGlslType.vec4,
    'mat2' => ShaderGlslType.mat2,
    'mat3' => ShaderGlslType.mat3,
    'mat4' => ShaderGlslType.mat4,
    'bool' => ShaderGlslType.bool,
    _ => throw UnimplementedError('Type not supported: $type'),
  };
}

ShaderVariable _readShaderVariable(String line) {
  final parts = line.split(_whitespace).map((e) => e.trim()).toList();
  if (parts.last.endsWith(';')) {
    parts.last = parts.last.substring(0, parts.last.length - 1);
  }

  if (parts.length == 2) {
    return ShaderVariable(typeGlsl: _readShaderGlslType(parts[0]), name: parts[1]);
  } else if (parts.length == 3) {
    if (parts[0] == 'in' || parts[0] == 'out') {
      return ShaderVariable(
        qualifier: _readShaderVariableQualifier(parts[0]),
        typeGlsl: _readShaderGlslType(parts[1]),
        name: parts[2],
      );
    } else {
      return ShaderVariable(
        precision: _readShaderVariablePrecision(parts[0]),
        typeGlsl: _readShaderGlslType(parts[1]),
        name: parts[2],
      );
    }
  } else if (parts.length == 4) {
    return ShaderVariable(
      qualifier: _readShaderVariableQualifier(parts[0]),
      precision: _readShaderVariablePrecision(parts[1]),
      typeGlsl: _readShaderGlslType(parts[2]),
      name: parts[3],
    );
  } else {
    throw UnimplementedError('Variable declaration not supported: $line');
  }
}
