import 'package:csslib/parser.dart' as css;
import 'package:vector_math/vector_math_64.dart';

/// A type that represents a color in the style spec.
///
/// It's an extension type of [Vector4] to simplify its usage in shaders.
/// 
/// Mirror `dart:ui` class is `ui.Color`, but it can't be used due to the need to run the code in a Dart-only context.
extension type Color._(Vector4 vec) {
  Color({required double r, required double g, required double b, double a = 1.0}) : this._(Vector4(r, g, b, a));

  /// Creates a new color from a list of numbers.
  ///
  /// The list must have at least 3 numbers, representing the red, green, and blue channels in the range 0-255.
  ///
  /// The fourth element is optional and represents the alpha channel in range 0-1. If it's not provided, default alpha
  /// value of 1.0 is used.
  factory Color.fromList(List<num> value) {
    return Color(
      r: value[0] / 255,
      g: value[1] / 255,
      b: value[2] / 255,
      a: value.length == 4 ? value[3].toDouble() : 1.0,
    );
  }

  /// Creates a new color from a CSS color string.
  factory Color.fromJson(String value) {
    // Convert percentages to 0-1 range because csslib doesn't support it
    // Collect [number]% and divide by 100
    var _value = value;

    // TODO: Color parsing with csslib sucks :( Maybe rewrite?
    final regex = RegExp(r'(\d+(\.\d+)?)%');
    _value = _value.replaceAllMapped(regex, (match) {
      final percentage = double.parse(match.group(1)!);
      return (percentage / 100).toString();
    });

    if (_value.startsWith('#')) {
      // Check for 3/4 digit hex
      if (_value.length == 4 || _value.length == 5) {
        // Duplicate each character, because csslib doesn't support 3/4 digit hex values
        _value = '#${_value.split('').skip(1).map((e) => e * 2).join()}';
      }
    }

    if (_value.startsWith('hsl')) {
      final inBrackets = _value.split('(').last.split(')').first;
      final parts = inBrackets.split(',').map((e) => e.trim()).toList();

      final h = double.parse(parts[0]);

      // H should be in range 0..1
      parts[0] = (h / 360).toString();

      if (_value.startsWith('hsla')) {
        _value = 'hsla(${parts.join(',')})';
      } else {
        _value = 'hsl(${parts.join(',')})';
      }
    }

    final _color = css.Color.css(_value);

    return Color(
      r: _color.rgba.r / 255,
      g: _color.rgba.g / 255,
      b: _color.rgba.b / 255,
      a: _color.rgba.a?.toDouble() ?? 1.0,
    );
  }

  /// Returns the red channel of the color in range `0-1`.
  double get r => vec.r;

  /// Returns the green channel of the color in range `0-1`.
  double get g => vec.g;

  /// Returns the blue channel of the color in range `0-1`.
  double get b => vec.b;

  /// Returns the alpha channel of the color in range `0-1`.
  double get a => vec.a;


  /// Returns the color representation as a list of numbers.
  List<double> get asRgbaList => vec.storage;
}
