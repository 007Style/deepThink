/// Shared conversation log for deepThink.
///
/// Maintains an ordered list of [Message] objects, notifies listeners via a
/// broadcast stream, and provides various slicing queries used by inference
/// workers and context management.
///
/// This file has zero Flutter imports — pure Dart only.
library conversation_log;

import 'dart:async';

import 'message.dart';

/// Shared, append-only conversation log.
///
/// All four AI workers and the user inject messages through [append].
/// Consumers subscribe to [messageStream] for real-time notifications and
/// use the query helpers ([getLastN], [getLastNForParticipant], etc.) to
/// build Ollama prompt payloads.
///
/// ```dart
/// final log = ConversationLog();
/// log.messageStream.listen((msg) => print(msg.toPlainText()));
/// log.append(Message(participantName: 'DEEP', content: 'Hello.', isUser: false));
/// ```
class ConversationLog {
  final List<Message> _messages = [];
  final StreamController<Message> _controller =
      StreamController<Message>.broadcast();

  /// All messages in insertion order.
  List<Message> get allMessages => List.unmodifiable(_messages);

  /// Broadcast stream that emits each new [Message] as it is appended.
  Stream<Message> get messageStream => _controller.stream;

  /// Appends [message] to the log and emits it on [messageStream].
  void append(Message message) {
    _messages.add(message);
    _controller.add(message);
  }

  /// Returns the last [n] messages across all participants, in order.
  ///
  /// If the log contains fewer than [n] messages the entire log is returned.
  List<Message> getLastN(int n) {
    if (n <= 0) return [];
    final start = _messages.length > n ? _messages.length - n : 0;
    return List.unmodifiable(_messages.sublist(start));
  }

  /// Returns the last [n] non-pass messages from [participantName], in order.
  ///
  /// Pass messages (empty content) are excluded.
  List<Message> getLastNForParticipant(String participantName, int n) {
    if (n <= 0) return [];
    final filtered = _messages
        .where((m) => m.participantName == participantName && !m.isPass)
        .toList();
    final start = filtered.length > n ? filtered.length - n : 0;
    return List.unmodifiable(filtered.sublist(start));
  }

  /// Returns the last [n] non-pass messages from **each** participant in
  /// [participantNames], interleaved in chronological order.
  ///
  /// Used to build the context-reset seed: passing `n = 2` gives the last 2
  /// substantive messages per participant (up to `n × participants.length`
  /// messages total).
  List<Message> getLastNPerParticipant(
      List<String> participantNames, int n) {
    if (n <= 0) return [];

    // Collect the last n non-pass messages per participant into a Set of ids
    // to preserve chronological ordering from the original list.
    final included = <String>{};
    for (final name in participantNames) {
      final msgs = _messages
          .where((m) => m.participantName == name && !m.isPass)
          .toList();
      final start = msgs.length > n ? msgs.length - n : 0;
      for (final m in msgs.sublist(start)) {
        included.add(m.id);
      }
    }

    return List.unmodifiable(
      _messages.where((m) => included.contains(m.id)).toList(),
    );
  }

  /// Formats the entire log as plain text.
  ///
  /// Each line uses the format `[HH:MM:SS] NAME: content`.
  /// Pass messages are omitted.
  String toPlainText() {
    return _messages
        .where((m) => !m.isPass)
        .map((m) => m.toPlainText())
        .join('\n');
  }

  /// Closes the underlying stream controller.
  ///
  /// Call when the conversation session ends to release resources.
  Future<void> dispose() => _controller.close();
}
