// User text input bar — sits above the status band.
//
// Shows the current user display name on the left, a multi-line text field in
// the centre, and a send button on the right.  Also sends on Enter (without
// Shift).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

// ---------------------------------------------------------------------------
// UserInputBar
// ---------------------------------------------------------------------------

/// Bottom input bar for the human user to interject in the conversation.
///
/// - [userName]  : displayed label (updates dynamically via easter egg).
/// - [enabled]   : disables input when no conversation is running.
/// - [onSubmit]  : called with the trimmed text when the user sends.
class UserInputBar extends StatefulWidget {
  /// Dynamic display name for the user label.
  final String userName;

  /// Whether the input is active (conversation is running).
  final bool enabled;

  /// Called with the non-empty trimmed text when the user submits.
  final void Function(String) onSubmit;

  const UserInputBar({
    required this.userName,
    required this.enabled,
    required this.onSubmit,
    super.key,
  });

  @override
  State<UserInputBar> createState() => _UserInputBarState();
}

class _UserInputBarState extends State<UserInputBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User name label
          SizedBox(
            width: 72,
            child: Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                // Send on Enter, new-line on Shift+Enter
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  final shift =
                      HardwareKeyboard.instance.isShiftPressed;
                  if (!shift && widget.enabled) {
                    _submit();
                  }
                }
              },
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                enabled: widget.enabled,
                maxLines: 3,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? 'Interject…'
                      : 'Start a conversation first',
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          SizedBox(
            width: 64,
            height: 34,
            child: ElevatedButton(
              onPressed: widget.enabled ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
