import 'package:flutter/material.dart';
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart';

class DebugExpansionTile extends StatefulWidget {
  const DebugExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.child,
    this.isElevated = false,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget child;
  final bool isElevated;

  @override
  State<DebugExpansionTile> createState() => _DebugExpansionTileState();
}

class _DebugExpansionTileState extends State<DebugExpansionTile> with AutomaticKeepAliveClientMixin {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListTileTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        borderRadius: widget.isElevated ? BorderRadius.circular(16.0) : BorderRadius.zero,
        elevation: widget.isElevated ? 4.0 : 0.0,
        clipBehavior: Clip.antiAlias,
        type: widget.isElevated ? MaterialType.canvas : MaterialType.transparency,
        child: Column(
          children: [
            SectionTitle(
              leading: widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              isExpanded: _isExpanded,
              onToggle: () {
                _isExpanded = !_isExpanded;
                setState(() {});
              },
            ),
            AnimatedCrossFade(
              firstChild: Container(height: 0.0),
              secondChild: widget.child,
              firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
              secondCurve: const Interval(0.0, 0.75, curve: Curves.fastOutSlowIn),
              sizeCurve: Curves.fastOutSlowIn,
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SectionCard extends StatefulWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.builder,
    this.leading,
  });

  final Widget? leading;
  final Widget title;
  final WidgetBuilder builder;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  @override
  Widget build(BuildContext context) {
    return DebugExpansionTile(
      isElevated: true,
      leading: widget.leading,
      title: widget.title,
      child: widget.builder(context),
    );
  }
}

class SectionList extends StatelessWidget {
  const SectionList({
    super.key,
    required this.children,
    this.automaticallyImplyDividers = true,
  });

  final List<Widget> children;
  final bool automaticallyImplyDividers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: automaticallyImplyDividers ? children.intersperse(const Divider(height: 0.0)).toList() : children,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    this.leading,
    this.subtitle,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
  });

  final Widget? leading;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onToggle,
      title: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!,
        child: title,
      ),
      subtitle: subtitle,
      leading: leading,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotatedBox(
            quarterTurns: isExpanded ? 3 : 1,
            child: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class HoverListenerWidget extends StatelessWidget {
  const HoverListenerWidget({super.key, required this.onHoverChanged, required this.child});

  final ValueChanged<bool> onHoverChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: child,
    );
  }
}
