import 'package:flutter/material.dart';
import 'package:notenest/core/theme/app_tokens.dart';

class NoteColorSwatch extends StatelessWidget {
  const NoteColorSwatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String semanticsLabel =
        '$label note color${selected ? ', selected' : ''}';
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: AppTokens.minimumTouchTarget,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color ?? colors.surface,
                  border: Border.all(
                    width: selected ? 3 : 1,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: colors.onSurface,
                      )
                    : color == null
                        ? const Icon(Icons.format_color_reset_rounded, size: 17)
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
