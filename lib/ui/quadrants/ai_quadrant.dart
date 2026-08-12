// Single AI character panel for the deepThink quadrant grid.
//
// Displays avatar, character name, model badge, live streaming tokens,
// and a "thinking…" indicator while inferring.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/conversation/message.dart';
import '../../core/conversation/participant.dart';
import '../avatars/avatar_registry.dart';
import '../avatars/avatar_widget.dart';
import '../avatars/energy_orb/orb_config.dart';
import '../widgets/app_theme.dart';

// ---------------------------------------------------------------------------
// AiQuadrant
// ---------------------------------------------------------------------------

/// A self-contained panel for one AI participant.
///
/// - Header: avatar + character name + model badge
/// - Body: scrollable message history + live streaming area
/// - Footer indicator: animated "thinking…" dots when [isThinking]
class AiQuadrant extends StatefulWidget {
  /// The AI participant this quadrant represents.
  final Participant participant;

  /// Completed messages from the shared conversation log for this participant
  /// AND all other participants (all messages are shown in each quadrant,
  /// but the name prefix distinguishes speakers).
  final List<Message> messages;

  /// Current avatar animation state.
  final AvatarState avatarState;

  /// Whether this participant is currently generating a response.
  final bool isThinking;

  /// Stream of raw token strings for the live-streaming text area.
  ///
  /// Each event is a new token to append to the current response buffer.
  final Stream<String> tokenStream;

  const AiQuadrant({
    required this.participant,
    required this.messages,
    required this.avatarState,
    required this.isThinking,
    required this.tokenStream,
    super.key,
  });

  @override
  State<AiQuadrant> createState() => _AiQuadrantState();
}

class _AiQuadrantState extends State<AiQuadrant>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  /// Tokens that have streamed in during the current generation turn.
  final StringBuffer _liveBuffer = StringBuffer();
  String _liveText = '';

  StreamSubscription<String>? _tokenSub;

  // Thinking-dots animation
  late final AnimationController _dotsCtrl;
  int _dotCount = 0;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subscribeToTokens();
    _updateDotsTimer();
  }

  @override
  void didUpdateWidget(AiQuadrant old) {
    super.didUpdateWidget(old);
    if (old.tokenStream != widget.tokenStream) {
      _tokenSub?.cancel();
      _subscribeToTokens();
    }
    if (old.isThinking != widget.isThinking) {
      _updateDotsTimer();
    }
    // When a new completed message arrives, clear the live buffer.
    if (old.messages.length != widget.messages.length) {
      setState(() {
        _liveBuffer.clear();
        _liveText = '';
      });
      _scrollToBottom();
    }
  }

  void _subscribeToTokens() {
    _tokenSub = widget.tokenStream.listen((token) {
      _liveBuffer.write(token);
      setState(() => _liveText = _liveBuffer.toString());
      _scrollToBottom();
    });
  }

  void _updateDotsTimer() {
    _dotsTimer?.cancel();
    if (widget.isThinking) {
      _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        setState(() => _dotCount = (_dotCount + 1) % 4);
      });
    } else {
      _dotCount = 0;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _dotsTimer?.cancel();
    _dotsCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Color _characterColor() {
    final config = OrbConfig.forCharacter(widget.participant.name);
    return config.primaryColor;
  }

  Color _nameColor(String participantName) {
    final config = OrbConfig.forCharacter(participantName);
    return config.primaryColor;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final charColor = _characterColor();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: charColor.withValues(alpha: 0.45), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            participant: widget.participant,
            avatarState: widget.avatarState,
            charColor: charColor,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Expanded(child: _MessageArea(
            messages: widget.messages,
            liveText: _liveText,
            liveParticipantName: widget.participant.name,
            scroll: _scroll,
            nameColorFn: _nameColor,
          )),
          if (widget.isThinking)
            _ThinkingIndicator(
              dotCount: _dotCount,
              charColor: charColor,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final Participant participant;
  final AvatarState avatarState;
  final Color charColor;

  const _Header({
    required this.participant,
    required this.avatarState,
    required this.charColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Avatar
          AvatarRegistry.build(
            'energyOrb',
            state: avatarState,
            characterName: participant.name,
            size: 52,
          ),
          const SizedBox(width: 10),
          // Name + model badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: charColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _ModelBadge(modelId: participant.assignedModelId),
                    const SizedBox(width: 6),
                    Text(
                      participant.personality,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ModelBadge
// ---------------------------------------------------------------------------

class _ModelBadge extends StatelessWidget {
  final String modelId;

  const _ModelBadge({required this.modelId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        modelId,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MessageArea
// ---------------------------------------------------------------------------

class _MessageArea extends StatelessWidget {
  final List<Message> messages;
  final String liveText;
  final String liveParticipantName;
  final ScrollController scroll;
  final Color Function(String) nameColorFn;

  const _MessageArea({
    required this.messages,
    required this.liveText,
    required this.liveParticipantName,
    required this.scroll,
    required this.nameColorFn,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: messages.length + (liveText.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          if (msg.isPass) return const SizedBox.shrink();
          return _MessageRow(
            name: msg.participantName,
            content: msg.content,
            nameColor: nameColorFn(msg.participantName),
            isUser: msg.isUser,
          );
        }
        // Live streaming row
        return _MessageRow(
          name: liveParticipantName,
          content: liveText,
          nameColor: nameColorFn(liveParticipantName),
          isUser: false,
          isStreaming: true,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _MessageRow
// ---------------------------------------------------------------------------

class _MessageRow extends StatelessWidget {
  final String name;
  final String content;
  final Color nameColor;
  final bool isUser;
  final bool isStreaming;

  const _MessageRow({
    required this.name,
    required this.content,
    required this.nameColor,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$name: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUser ? AppColors.accent : nameColor,
              ),
            ),
            TextSpan(
              text: content,
              style: TextStyle(
                fontSize: 12,
                color: isStreaming
                    ? AppColors.textPrimary.withValues(alpha: 0.85)
                    : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ThinkingIndicator
// ---------------------------------------------------------------------------

class _ThinkingIndicator extends StatelessWidget {
  final int dotCount;
  final Color charColor;

  const _ThinkingIndicator({
    required this.dotCount,
    required this.charColor,
  });

  @override
  Widget build(BuildContext context) {
    final dots = '.' * (dotCount + 1);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.statusBackground,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: charColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'thinking$dots',
            style: TextStyle(
              fontSize: 10,
              color: charColor.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
