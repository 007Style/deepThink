// 2×2 grid of AiQuadrant panels that fills available space.
import 'package:flutter/material.dart';

import '../../core/conversation/message.dart';
import '../../core/conversation/participant.dart';
import '../avatars/avatar_widget.dart';
import 'ai_quadrant.dart';

// ---------------------------------------------------------------------------
// QuadrantData — per-quadrant state bundle
// ---------------------------------------------------------------------------

/// All runtime state needed to render one [AiQuadrant].
class QuadrantData {
  final Participant participant;
  final List<Message> messages;
  final AvatarState avatarState;
  final bool isThinking;
  final Stream<String> tokenStream;

  const QuadrantData({
    required this.participant,
    required this.messages,
    required this.avatarState,
    required this.isThinking,
    required this.tokenStream,
  });
}

// ---------------------------------------------------------------------------
// QuadrantGrid
// ---------------------------------------------------------------------------

/// Renders four [AiQuadrant] widgets in a 2×2 layout.
///
/// The grid fills the available space proportionally, with a 4 px gap between
/// panels. [quadrants] must have exactly 4 elements, in the order:
/// top-left, top-right, bottom-left, bottom-right.
class QuadrantGrid extends StatelessWidget {
  /// Exactly 4 data bundles — one per quadrant.
  final List<QuadrantData> quadrants;

  const QuadrantGrid({
    required this.quadrants,
    super.key,
  }) : assert(quadrants.length == 4,
            'QuadrantGrid requires exactly 4 QuadrantData entries');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top row
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildQuadrant(0)),
              const SizedBox(width: 4),
              Expanded(child: _buildQuadrant(1)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Bottom row
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildQuadrant(2)),
              const SizedBox(width: 4),
              Expanded(child: _buildQuadrant(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrant(int index) {
    final d = quadrants[index];
    return AiQuadrant(
      key: ValueKey(d.participant.name),
      participant: d.participant,
      messages: d.messages,
      avatarState: d.avatarState,
      isThinking: d.isThinking,
      tokenStream: d.tokenStream,
    );
  }
}
