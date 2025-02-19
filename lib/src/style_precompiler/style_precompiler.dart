import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/src/renderer/supported_layers.dart';

import 'package:gpu_vector_tile_renderer/src/shaders/gen/shader_templates.gen.dart' as shader_templates;
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/shader_reader.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/shader_writer.dart';
import 'package:gpu_vector_tile_renderer/src/spec/gen/expressions.gen.dart';
import 'package:gpu_vector_tile_renderer/src/utils/string_utils.dart';

// TODO: This is an experimental version of this. Code is absolutely unreadable.
// Once it's stabilized, I'll rewrite it to be more concise and easier to read.

const _emptyEvaluationContext = spec.EvaluationContext.empty();

Map<String, (ParsedShader, ParsedShader)> precompileStyle(spec.Style style) {
  final result = <String, (ParsedShader, ParsedShader)>{};
  final supportedLayers = style.layers.where(isLayerSupported);

  for (final layer in supportedLayers) {
    final shaderName = toSnakeCase(layer.id);
    final output = _precompileFillLayer(layer as spec.LayerFill);
    result[shaderName] = output;
  }

  return result;
}

(ParsedShader, ParsedShader) _precompileFillLayer(spec.LayerFill layer) {
  final paint = layer.paint;

  return _precompileLayer(
    layer,
    shaderName: toSnakeCase(layer.id),
    templateName: 'fill',
    onPropertyDeclaration: (name) {
      return switch (name) {
        'antialias' => paint.fillAntialias,
        'opacity' => paint.fillOpacity,
        'color' => paint.fillColor,
        'translate' => paint.fillTranslate,
        _ => throw UnimplementedError('Property not supported: $name'),
      };
    },
  );
}

enum _PropertyDeclarationType { uniform, attribute, constant }

enum _PropertyDeclarationInterpolation { crossfade, interpolate, step }

class _PropertyDeclarationResult {
  _PropertyDeclarationResult({required this.type, this.interpolation, this.constantValue, this.interpolationStops});

  final _PropertyDeclarationType type;
  final _PropertyDeclarationInterpolation? interpolation;
  final Object? constantValue;
  final List<double>? interpolationStops;
}

(ParsedShader, ParsedShader) _precompileLayer<T extends spec.Layer>(
  T layer, {
  required String shaderName,
  required String templateName,
  required spec.Property Function(String) onPropertyDeclaration,
}) {
  final vertexShaderSource = shader_templates.vertexShaderTemplates[templateName]!;
  final fragmentShaderSource = shader_templates.fragmentShaderTemplates[templateName]!;

  final vertexShader = readShader(vertexShaderSource, name: templateName, type: ShaderType.vertex);
  final fragmentShader = readShader(fragmentShaderSource, name: templateName, type: ShaderType.fragment);

  final _declarationMap = <PropDeclarationShaderPragma, _PropertyDeclarationResult>{};
  final _vertexResolutionMap = <PropDeclarationShaderPragma, List<Object>>{};
  final _fragmentResolutionMap = <PropDeclarationShaderPragma, List<Object>>{};

  // Property declaration pass
  for (var i = 0; i < vertexShader.content.length; i++) {
    final element = vertexShader.content[i];

    if (element is PropDeclarationShaderPragma) {
      final property = onPropertyDeclaration(element.variable.name);
      _declarationMap[element] = _precompilePropertyDeclaration(property);
    }
  }

  void _replacePragma(ParsedShader shader, PropDeclarationShaderPragma pragma, Object? value) {
    final index = shader.content.indexOf(pragma);
    assert(index != -1);

    if (value == null) {
      shader.content.removeAt(index);
    } else if (value is List) {
      shader.content.removeAt(index);
      shader.content.insertAll(index, value.whereType<Object>());
    } else {
      shader.content[index] = value;
    }
  }

  void _insertUbo(ParsedShader shader, ShaderUbo ubo) {
    var index = shader.content.lastIndexOf((e) => e is PropDeclarationShaderPragma);
    if (index == -1) {
      index = shader.content.indexOf((e) => e == 'void main() {') - 1;
    }

    shader.content.insert(index, ubo);
  }

  final ubo = ShaderUbo(name: 'Layer${layer.id}', instanceName: 'layer${layer.id}', variables: []);

  List<Object> _getGenericAttributeResolution(
    PropDeclarationShaderPragma pragma,
    _PropertyDeclarationResult result,
    List<ShaderVariable> variables,
    String Function(String) accessor,
  ) {
    final variable = pragma.variable;

    if (variables.length == 1) {
      return [variable.copyWith(value: accessor(variables.single.name))];
    } else {
      // Interpolation
      final startValueAccessor = accessor(variables[0].name);
      final endValueAccessor = accessor(variables[1].name);
      final startStopAccessor = accessor('${variable.name}_start_stop');
      final endStopAccessor = accessor('${variable.name}_end_stop');

      if (result.interpolation == _PropertyDeclarationInterpolation.crossfade) {
        return [variable.copyWith(value: 'data_crossfade($startValueAccessor, $endValueAccessor)')];
      } else if (result.interpolation == _PropertyDeclarationInterpolation.step) {
        return [
          variable.copyWith(
            value: 'data_step($startValueAccessor, $endValueAccessor, $startStopAccessor, $endStopAccessor)',
          ),
        ];
      } else if (result.interpolation == _PropertyDeclarationInterpolation.interpolate) {
        return [
          variable.copyWith(
            value: 'data_interpolate($startValueAccessor, $endValueAccessor, $startStopAccessor, $endStopAccessor)',
          ),
        ];
      } else {
        throw UnimplementedError('Interpolation type not supported: ${result.interpolation}');
      }
    }
  }

  for (final declaration in _declarationMap.entries) {
    final pragma = declaration.key;
    final result = declaration.value;

    if (result.type == _PropertyDeclarationType.constant) {
      assert(result.constantValue != null);

      final variable = pragma.variable.copyWith(qualifier: ShaderVariableQualifier.const_, value: result.constantValue);

      _replacePragma(vertexShader, pragma, variable);
      _replacePragma(fragmentShader, pragma, variable);

      _vertexResolutionMap[pragma] = [];
    } else {
      List<ShaderVariable> variables;
      List<ShaderVariable> interpolationVariables;

      if (result.interpolation == null) {
        variables = [pragma.variable];
        interpolationVariables = [];
      } else {
        variables = [
          pragma.variable.copyWith(name: '${pragma.variable.name}_start_value'),
          pragma.variable.copyWith(name: '${pragma.variable.name}_end_value'),
        ];

        interpolationVariables = [
          pragma.variable.copyWith(name: '${pragma.variable.name}_start_stop'),
          pragma.variable.copyWith(name: '${pragma.variable.name}_end_stop'),
        ];
      }

      if (result.type == _PropertyDeclarationType.uniform) {
        _replacePragma(vertexShader, pragma, null);
        _replacePragma(fragmentShader, pragma, null);

        ubo.variables.addAll([...variables, ...interpolationVariables]);
        _vertexResolutionMap[pragma] = _getGenericAttributeResolution(
          pragma,
          result,
          variables,
          (v) => '${ubo.instanceName}.$v',
        );
        _fragmentResolutionMap[pragma] = _vertexResolutionMap[pragma]!;
      } else if (result.type == _PropertyDeclarationType.attribute) {
        _replacePragma(vertexShader, pragma, [
          ...interpolationVariables.map((v) => v.copyWith(qualifier: ShaderVariableQualifier.in_)),
          ...variables.map((v) => v.copyWith(qualifier: ShaderVariableQualifier.in_)),
          pragma.variable.copyWith(qualifier: ShaderVariableQualifier.out_, name: 'v_${pragma.variable.name}'),
        ]);

        _replacePragma(
          fragmentShader,
          pragma,
          pragma.variable.copyWith(qualifier: ShaderVariableQualifier.in_, name: 'v_${pragma.variable.name}'),
        );

        _vertexResolutionMap[pragma] = [
          ..._getGenericAttributeResolution(pragma, result, variables, (v) => v),
          'v_${pragma.variable.name} = ${pragma.variable.name};',
        ];

        _fragmentResolutionMap[pragma] = [pragma.variable.copyWith(value: 'v_${pragma.variable.name}')];
      }
    }
  }

  if (ubo.variables.isNotEmpty) {
    _insertUbo(vertexShader, ubo);
    _insertUbo(fragmentShader, ubo);
  }

  // Property declaration pass
  for (var i = 0; i < vertexShader.content.length; i++) {
    final element = vertexShader.content[i];

    if (element is PropResolutionShaderPragma) {
      vertexShader.content.removeAt(i);

      final resolutions = element.resolutions;
      // Currently only ... resolution is supported.
      assert(resolutions.single == '...');

      for (final resolution in _vertexResolutionMap.values) {
        vertexShader.content.insertAll(i, resolution);
      }

      break;
    }
  }
  // Property declaration pass
  for (var i = 0; i < fragmentShader.content.length; i++) {
    final element = fragmentShader.content[i];

    if (element is PropResolutionShaderPragma) {
      fragmentShader.content.removeAt(i);

      final resolutions = element.resolutions;
      // Currently only ... resolution is supported.
      assert(resolutions.single == '...');

      for (final resolution in _fragmentResolutionMap.values) {
        fragmentShader.content.insertAll(i, resolution);
      }

      break;
    }
  }

  // Prelude pass
  while (true) {
    final firstPreludePragmaIndex = vertexShader.content.indexWhere((e) => e is PreludeShaderPragma);
    if (firstPreludePragmaIndex == -1) break;

    final prelude = vertexShader.content.removeAt(firstPreludePragmaIndex) as PreludeShaderPragma;
    vertexShader.content.insert(firstPreludePragmaIndex, shader_templates.preludeShaders[prelude.name]!);
  }

  while (true) {
    final firstPreludePragmaIndex = fragmentShader.content.indexWhere((e) => e is PreludeShaderPragma);
    if (firstPreludePragmaIndex == -1) break;

    final prelude = fragmentShader.content.removeAt(firstPreludePragmaIndex) as PreludeShaderPragma;
    fragmentShader.content.insert(firstPreludePragmaIndex, shader_templates.preludeShaders[prelude.name]!);
  }

  return (
    readShader(writeShader(vertexShader), name: shaderName, type: ShaderType.vertex),
    readShader(writeShader(fragmentShader), name: shaderName, type: ShaderType.fragment),
  );
}

_PropertyDeclarationResult _precompilePropertyDeclaration(spec.Property property) {
  // TODO: CLEAN UP THIS CODE!
  final hasExpression = property.expression != null;

  final dependencies = hasExpression ? property.expression!.dependencies : const <spec.ExpressionDependency>{};

  final hasDependencies = dependencies.isNotEmpty;
  final hasDataDependency = hasExpression && dependencies.contains(spec.ExpressionDependency.data);
  final hasCameraDependency = hasExpression && dependencies.contains(spec.ExpressionDependency.camera);

  if (property is spec.ConstantProperty || !hasExpression || !hasDependencies) {
    // Property value is always constant, no matter the evaluation context.
    // Shader receives the value baked into the shader.
    final value = property.evaluate(_emptyEvaluationContext);
    return _PropertyDeclarationResult(type: _PropertyDeclarationType.constant, constantValue: value);
  } else if (property is spec.DataConstantProperty) {
    // Property value is the same for all features.
    // Shader receives the value as a uniform.
    assert(!property.expression!.dependencies.contains(spec.ExpressionDependency.data));
    return _PropertyDeclarationResult(type: _PropertyDeclarationType.uniform);
  } else if (property is spec.CrossFadedProperty ||
      (property is spec.CrossFadedDataDrivenProperty && !hasDataDependency)) {
    // Property value is the same for all features.
    // Output is cross-faded between two values based on a zoom-dependent interpolation.
    // Shader receives two values to cross-fade between as a uniform.
    return _PropertyDeclarationResult(
      type: _PropertyDeclarationType.uniform,
      interpolation: _PropertyDeclarationInterpolation.crossfade,
    );
  } else if (property is spec.CrossFadedDataDrivenProperty) {
    // Property value is different between features.
    // Output is cross-faded between two values based on a zoom-dependent interpolation.
    // Shader receives two values to cross-fade between as a vertex attribute.
    assert(property.expression!.dependencies.contains(spec.ExpressionDependency.data));
    return _PropertyDeclarationResult(
      type: _PropertyDeclarationType.attribute,
      interpolation: _PropertyDeclarationInterpolation.crossfade,
    );
  } else if (property is spec.DataDrivenProperty) {
    // Property value is different between features.
    //
    // Depending on the expression type, the following will happen:
    // 1. Zoom is used (subsequently as an input to a step/interpolation):
    //    - Shader will receive the interpolation values for the two nearest zoom levels as vertex attributes
    //    - Shader will have the interpolation code baked in
    //    - Result is interpolated between the two values based on the zoom level
    // 2. Zoom is not used:
    //    - Shader will receive the value as a vertex attribute
    if (hasCameraDependency) {
      if (property.expression! is StepExpression) {
        final stepExpr = property.expression! as StepExpression;

        return _PropertyDeclarationResult(
          type: _PropertyDeclarationType.attribute,
          interpolation: _PropertyDeclarationInterpolation.step,
          interpolationStops: stepExpr.stops.map((stop) => stop.$1.toDouble()).toList(),
        );
      } else if (property.expression! is InterpolateExpression) {
        final interpolateExpr = property.expression! as InterpolateExpression;

        // TODO: Interpolation settings

        return _PropertyDeclarationResult(
          type: _PropertyDeclarationType.attribute,
          interpolation: _PropertyDeclarationInterpolation.interpolate,
          interpolationStops: interpolateExpr.stops.map((stop) => stop.$1.toDouble()).toList(),
        );
      } else {
        throw UnimplementedError('Expression type not supported: ${property.expression!.runtimeType}');
      }
    } else {
      return _PropertyDeclarationResult(type: _PropertyDeclarationType.attribute);
    }
  } else {
    throw UnimplementedError('Property type not supported: $property');
  }
}
