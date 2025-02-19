import 'package:gpu_vector_tile_renderer/src/spec/expression/_definition_imports.dart';

@ExpressionAnnotation('ZoomExpression', rawName: 'zoom', ownDependencies: ExpressionDependency.camera)
num zoomExpressionImpl(EvaluationContext context) => context.zoom;
