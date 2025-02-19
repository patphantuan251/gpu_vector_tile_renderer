import 'package:equatable/equatable.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart';

/// A class that represents a section of formatted text.
/// 
/// Used inside of [Formatted] and represents a contiguous section of text with the same formatting.
class FormattedSection with EquatableMixin {
  const FormattedSection({
    required this.text,
    this.image,
    this.scale,
    this.fontStack,
    this.textColor,
  });

  /// The text of the section.
  final String text;

  /// The background image to apply to this section.
  final ResolvedImage? image;

  /// The scale of the text. If not provided, the text will be rendered at 1.0 scale.
  final num? scale;

  /// The font stack to use for the text.
  final String? fontStack;

  /// The color of the text.
  final num? textColor;

  @override
  List<Object?> get props => [text, image, scale, fontStack, textColor];
}

/// A class representing formatted text in the context of the style spec.
/// 
/// Formatted text is a list of [FormattedSection]s, each of which represents a contiguous section of text with the same 
/// formatting applied.
class Formatted with EquatableMixin {
  const Formatted({
    required this.sections,
  });

  /// Creates a [Formatted] with an empty mutable list of sections.
  Formatted.empty() : sections = [];

  /// List of text sections in this formatted text.
  final List<FormattedSection> sections;

  /// Creates a [Formatted] from a JSON string.
  /// 
  /// TODO: Actually implement this. Currently, this is just a stub.
  factory Formatted.fromJson(String unformatted) {
    return Formatted(sections: [FormattedSection(text: unformatted)]);
  }

  @override
  List<Object?> get props => [sections];
}
