import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A stable single-row composer. Typing grows only the text field upward;
/// attachment and send controls remain available at the bottom edge.
class CommentComposer extends StatelessWidget {
  const CommentComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.avatar,
    required this.brandColor,
    required this.expanded,
    required this.onImage,
    required this.onSend,
    this.hint = 'Add comments...',
    this.sending = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget avatar;
  final Color brandColor;
  final bool expanded;
  final VoidCallback? onImage;
  final VoidCallback? onSend;
  final String hint;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ClipOval(child: avatar),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: sending,
                    minLines: expanded ? 2 : 1,
                    maxLines: 4,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('comment-image'),
                  tooltip: 'Attach image',
                  onPressed: sending ? null : onImage,
                  icon: Icon(
                    PhosphorIcons.image(),
                    size: 24,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: brandColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      key: const ValueKey('comment-send'),
                      tooltip: sending ? 'Sending comment' : 'Send comment',
                      onPressed: sending ? null : onSend,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: Icon(
                        PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
