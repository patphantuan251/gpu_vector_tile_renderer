import 'package:equatable/equatable.dart';
import 'package:gpu_vector_tile_renderer/src/utils/string_utils.dart';

/// Represents a shader type.
enum ShaderType {
  vertex._('.vert'),
  fragment._('.frag');

  const ShaderType._(this.fileExtension);

  /// Contains the file extension for the shader type.
  final String fileExtension;
}

/// Represents a qualifier used by a shader variable.
enum ShaderVariableQualifier {
  in_._('in'),
  out_._('out'),
  const_._('const');

  const ShaderVariableQualifier._(this.value);

  final String value;
}

/// Represents a variable precision used by a shader.
enum ShaderVariablePrecision {
  highp._('highp'),
  mediump._('mediump'),
  lowp._('lowp');

  const ShaderVariablePrecision._(this.value);

  final String value;
}

/// Represents a GLSL type.
enum ShaderGlslType {
  float._('float', 'double', 4),
  int_._('int', 'int', 4),
  vec2._('vec2', 'Vector2', 8),
  vec3._('vec3', 'Vector3', 12),
  vec4._('vec4', 'Vector4', 16),
  mat2._('mat2', 'Matrix2', 16),
  mat3._('mat3', 'Matrix3', 36),
  mat4._('mat4', 'Matrix4', 64),
  bool._('bool', 'bool', 4);

  const ShaderGlslType._(this.value, this.dartType, this.sizeInBytes);

  final String value;
  final String dartType;
  final int sizeInBytes;
}

/// Represents a variable used by a shader.
class ShaderVariable with EquatableMixin {
  const ShaderVariable({
    this.qualifier,
    this.precision,
    required this.typeGlsl,
    this.arrayLength,
    required this.name,
    this.value,
  });

  /// Qualifier, if specified.
  final ShaderVariableQualifier? qualifier;

  /// Precision, if specified.
  final ShaderVariablePrecision? precision;

  /// GLSL type of the variable.
  final ShaderGlslType typeGlsl;

  /// Array length, if specified.
  final int? arrayLength;

  /// Name of the variable.
  final String name;

  /// Value of the variable, if specified.
  final Object? value;

  int get sizeInBytes => typeGlsl.sizeInBytes;

  String get dartType {
    if (arrayLength != null) {
      return 'List<${typeGlsl.dartType}>';
    } else {
      return typeGlsl.dartType;
    }
  }

  String dartName([String? prefix]) {
    final name = nameToDartFieldName(this.name);
    return prefix != null ? '$prefix$name' : name;
  }

  ShaderVariable copyWith({
    ShaderVariableQualifier? qualifier,
    ShaderVariablePrecision? precision,
    ShaderGlslType? typeGlsl,
    int? arrayLength,
    String? name,
    Object? value,
  }) {
    return ShaderVariable(
      qualifier: qualifier ?? this.qualifier,
      precision: precision ?? this.precision,
      typeGlsl: typeGlsl ?? this.typeGlsl,
      arrayLength: arrayLength ?? this.arrayLength,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [qualifier, precision, typeGlsl, arrayLength, name, value];
}


/// Represents a Uniform Buffer Object (UBO) used by a shader.
class ShaderUbo with EquatableMixin {
  const ShaderUbo({required this.name, required this.instanceName, required this.variables});

  /// Name of the UBO.
  final String name;

  /// Variables in the UBO.
  final List<ShaderVariable> variables;

  /// Name of the instance of the UBO.
  final String instanceName;

  String get dartClassName => '${nameToDartClassName(name)}Ubo';

  @override
  List<Object?> get props => [name, variables];
}

/// Represents a pragma keyword used by a shader.
///
/// Currently two pragmas are recognized:
/// - [PreludeShaderPragma]
/// - [PropShaderPragma]
class ShaderPragma with EquatableMixin {
  const ShaderPragma({required this.value});

  final String value;

  @override
  List<Object?> get props => [value];
}

/// Represents a `prelude` pragma used by a shader.
///
/// Example: `#pragma prelude: tile`, where `tile` is the name of the prelude.
class PreludeShaderPragma extends ShaderPragma {
  const PreludeShaderPragma({required this.name, required super.value});

  /// Name of the prelude.
  final String name;
}

/// Represents a `prop` declaration pragma used by a shader.
///
/// Example: `#pragma prop: declare(highp vec4 color)`.
class PropDeclarationShaderPragma extends ShaderPragma {
  PropDeclarationShaderPragma({required this.variable, required super.value});

  final ShaderVariable variable;
}

/// Represents a `prop` resolution pragma used by a shader.
///
/// Example: `#pragma prop: resolve(...)`.
class PropResolutionShaderPragma extends ShaderPragma {
  PropResolutionShaderPragma({required this.resolutions, required super.value});

  final List<String> resolutions;
}

/// Represents a parsed shader, with specific pragmas and metadata used by the style/shader compiler.
///
/// See [ParsedShaderVertex] and [ParsedShaderFragment] for specific implementations.
///
/// You can use `shader_reader.dart` and `shader_writer.dart` to read/write shaders.
abstract class ParsedShader with EquatableMixin {
  const ParsedShader({required this.name, required this.type, required this.content});

  /// Name of the shader. E.g. if the file name is `fill.frag`, the name is `fill`.
  final String name;

  /// Type of the shader.
  final ShaderType type;

  /// Content of the shader. Types in the list can be:
  /// - [String] - for regular GLSL code
  /// - [ShaderPragma] - for pragmas
  /// - [ShaderVariable] - for attributes
  /// - [ShaderUbo] - for UBOs
  final List<Object> content;

  /// List of UBOs in the [content].
  Iterable<ShaderUbo> get ubos => content.whereType<ShaderUbo>();

  /// List of pragmas in the [content].
  Iterable<ShaderPragma> get pragmas => content.whereType<ShaderPragma>();

  String get dartClassName;

  String get shaderBundleName;

  @override
  List<Object?> get props => [name, type, content];

  ParsedShader copyWithName(String name) {
    if (this is ParsedShaderVertex) {
      return ParsedShaderVertex(name: name, type: type, content: content);
    } else if (this is ParsedShaderFragment) {
      return ParsedShaderFragment(name: name, type: type, content: content);
    } else {
      throw Exception('Unknown shader type');
    }
  }
}

/// Represents a parsed vertex shader.
class ParsedShaderVertex extends ParsedShader {
  ParsedShaderVertex({required super.name, required super.type, required super.content});

  /// List of vertex attributes in the [content].
  Iterable<ShaderVariable> get attributes =>
      content.whereType<ShaderVariable>().where((a) => a.qualifier == ShaderVariableQualifier.in_);

  /// List of vertex outputs in the [content].
  Iterable<ShaderVariable> get outputs =>
      content.whereType<ShaderVariable>().where((a) => a.qualifier == ShaderVariableQualifier.out_);

  int get bytesPerVertex => attributes.fold(0, (acc, vari) => acc + vari.sizeInBytes);

  @override
  String get dartClassName => '${nameToDartClassName(name)}VertexShaderBindings';

  @override
  String get shaderBundleName => '${name}_vert';
}

/// Represents a parsed fragment shader.
class ParsedShaderFragment extends ParsedShader {
  ParsedShaderFragment({required super.name, required super.type, required super.content});

  /// List of input variables that are passed from the vertex shader in the [content].
  Iterable<ShaderVariable> get inputs =>
      content.whereType<ShaderVariable>().where((a) => a.qualifier == ShaderVariableQualifier.in_);

  @override
  String get dartClassName => '${nameToDartClassName(name)}FragmentShaderBindings';

  @override
  String get shaderBundleName => '${name}_frag';
}
