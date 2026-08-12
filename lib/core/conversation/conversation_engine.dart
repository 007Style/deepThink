/// Conversation engine for deepThink.
///
/// Top-level orchestrator that owns the four [InferenceWorker] instances,
/// manages start/stop lifecycle, injects user messages, and exposes a
/// merged [eventStream] for the UI layer.
///
/// This file has zero Flutter imports — pure Dart only.
library conversation_engine;

import 'dart:async';

import '../context/context_manager.dart';
import '../ollama/hardware_detector.dart';
import '../ollama/ollama_client.dart';
import 'conversation_log.dart';
import 'inference_worker.dart';
import 'message.dart';
import 'participant.dart';

// ---------------------------------------------------------------------------
// ConversationEngine
// ---------------------------------------------------------------------------

/// Orchestrates all four AI [InferenceWorker] instances.
///
/// The engine:
/// - Owns the shared [ConversationLog] that all workers read from and write to.
/// - Creates one [InferenceWorker] per [Participant] on [start].
/// - Merges all four worker event streams into a single [eventStream].
/// - Provides [injectUserMessage] so the UI can push user utterances into
///   the conversation.
/// - Shuts everything down cleanly on [stop].
///
/// ```dart
/// final engine = ConversationEngine(client: ollamaClient);
/// final hardware = await HardwareDetector.detect();
/// await engine.start(Participant.defaults(), hardware);
///
/// engine.eventStream.listen((event) {
///   if (event.token != null) print('${event.participantName}: ${event.token}');
/// });
///
/// engine.injectUserMessage('User', 'What do you all think about AI?');
/// // ... later ...
/// await engine.stop();
/// ```
class ConversationEngine {
  /// The Ollama REST API client shared by all workers.
  final OllamaClient client;

  final ConversationLog _log = ConversationLog();
  final ContextManager _contextManager = ContextManager();

  List<InferenceWorker> _workers = [];
  StreamSubscription<InferenceEvent>? _mergedSubscription;
  StreamController<InferenceEvent>? _eventController;

  bool _started = false;

  /// Creates a [ConversationEngine].
  ConversationEngine({required this.client});

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// The shared conversation log.
  ConversationLog get log => _log;

  /// Merged broadcast stream of [InferenceEvent]s from all four workers.
  ///
  /// Available after [start] is called. Emitting events from all workers on
  /// one stream simplifies UI subscription — consumers can filter by
  /// [InferenceEvent.participantName].
  Stream<InferenceEvent> get eventStream {
    assert(_eventController != null,
        'eventStream accessed before start() was called');
    return _eventController!.stream;
  }

  /// Initialises all workers and begins the conversation.
  ///
  /// [participants] must contain exactly the four AI participants.
  /// [hardware] is used by each worker for context window sizing.
  ///
  /// This method is idempotent — calling it when already started is a no-op.
  Future<void> start(
      List<Participant> participants, HardwareInfo hardware) async {
    if (_started) return;
    _started = true;

    _eventController = StreamController<InferenceEvent>.broadcast();

    _workers = participants
        .map(
          (p) => InferenceWorker(
            participant: p,
            log: _log,
            client: client,
            hardware: hardware,
            contextManager: _contextManager,
          ),
        )
        .toList();

    // Merge all four worker streams into the single broadcast controller.
    final merged = StreamGroup.merge(
      _workers.map((w) => w.eventStream).toList(),
    );
    _mergedSubscription = merged.listen(
      (event) {
        if (!(_eventController?.isClosed ?? true)) {
          _eventController!.add(event);
        }
      },
      onError: (Object error) {
        // Swallow individual worker errors to keep the engine alive.
      },
    );

    // Start all workers.
    for (final worker in _workers) {
      worker.start(participants);
    }

    // DEEP (host) kicks off the conversation by receiving a synthetic
    // "start" message that only the host sees as a trigger.
    final kickoff = Message(
      participantName: 'System',
      content:
          'The conversation is beginning. DEEP, please open with a thought-provoking topic or question.',
      isUser: false,
    );
    _log.append(kickoff);
  }

  /// Gracefully stops all workers and releases resources.
  ///
  /// After [stop] the engine cannot be restarted — create a new instance.
  Future<void> stop() async {
    _started = false;
    await _mergedSubscription?.cancel();

    await Future.wait(_workers.map((w) => w.stop()));
    _workers.clear();

    await _eventController?.close();
    _eventController = null;

    await _log.dispose();
  }

  /// Injects a message from the human user into the shared log.
  ///
  /// All workers will see the message on [ConversationLog.messageStream] and
  /// decide independently whether to respond.
  ///
  /// [userName] is the current display name for the user (default `"User"`).
  /// [content] must be non-empty.
  void injectUserMessage(String userName, String content) {
    if (content.trim().isEmpty) return;

    final message = Message(
      participantName: userName,
      content: content.trim(),
      isUser: true,
    );
    _log.append(message);
  }
}

// ---------------------------------------------------------------------------
// StreamGroup helper (avoids the async package dependency)
// ---------------------------------------------------------------------------

/// Merges multiple streams into a single broadcast stream.
///
/// This is a minimal internal utility so that `package:async` is not required
/// in a pure-Dart core file.
class StreamGroup {
  /// Returns a broadcast [Stream] that emits events from all [streams].
  ///
  /// The combined stream closes when all source streams have closed.
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    int openCount = streams.length;

    void onDone() {
      openCount--;
      if (openCount == 0) {
        controller.close();
      }
    }

    final subscriptions = <StreamSubscription<T>>[];

    controller = StreamController<T>.broadcast(
      onListen: () {
        for (final stream in streams) {
          final sub = stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: onDone,
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }
}
