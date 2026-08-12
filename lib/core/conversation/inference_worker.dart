/// Per-AI inference worker for deepThink.
///
/// Each [InferenceWorker] monitors the shared [ConversationLog], applies a
/// random jitter before responding, calls [OllamaClient.generateStream], and
/// streams [InferenceEvent] tokens back to the [ConversationEngine].
///
/// Context-window resets are handled transparently via [ContextManager].
///
/// This file has zero Flutter imports — pure Dart only.
library inference_worker;

import 'dart:async';
import 'dart:math';

import '../context/context_manager.dart';
import '../ollama/hardware_detector.dart';
import '../ollama/ollama_client.dart';
import 'conversation_log.dart';
import 'message.dart';
import 'participant.dart';
import 'system_prompt_builder.dart';

// ---------------------------------------------------------------------------
// InferenceEvent
// ---------------------------------------------------------------------------

/// A single event emitted by an [InferenceWorker].
///
/// Consumers should check:
/// - [token] is non-null → append it to the participant's current response.
/// - [token] is null and [isDone] is `true` → generation for this turn is complete.
/// - [isThinking] is `true` → the worker is deciding whether to respond (jitter phase).
class InferenceEvent {
  /// Name of the participant producing this event.
  final String participantName;

  /// Incremental text token, or `null` when [isDone] is `true`.
  final String? token;

  /// `true` once the worker has finished streaming a full response (or pass).
  final bool isDone;

  /// `true` during the jitter window before inference begins.
  final bool isThinking;

  /// `true` when the participant decided to pass (empty response).
  final bool isPass;

  /// Creates an [InferenceEvent].
  const InferenceEvent({
    required this.participantName,
    this.token,
    this.isDone = false,
    this.isThinking = false,
    this.isPass = false,
  });

  @override
  String toString() =>
      'InferenceEvent($participantName, token=$token, done=$isDone, '
      'thinking=$isThinking, pass=$isPass)';
}

// ---------------------------------------------------------------------------
// InferenceWorker
// ---------------------------------------------------------------------------

/// Drives inference for a single AI [Participant].
///
/// The worker subscribes to [ConversationLog.messageStream] and reacts to
/// every new message. It waits a random jitter (200–800 ms) before calling
/// Ollama, which prevents all four AIs from responding simultaneously.
///
/// Start the worker with [start] and stop it cleanly with [stop].
/// All events are available on [eventStream].
///
/// ```dart
/// final worker = InferenceWorker(
///   participant: participants[0],
///   log: conversationLog,
///   client: ollamaClient,
///   hardware: hardwareInfo,
///   contextManager: ctxManager,
/// );
/// worker.start(allParticipants);
/// worker.eventStream.listen((e) { ... });
/// ```
class InferenceWorker {
  /// The AI character this worker drives.
  final Participant participant;

  /// The shared conversation log.
  final ConversationLog log;

  /// Ollama REST API client.
  final OllamaClient client;

  /// Detected hardware — used for context window selection.
  final HardwareInfo hardware;

  /// Shared context manager — tracks token usage across all workers.
  final ContextManager contextManager;

  final StreamController<InferenceEvent> _eventController =
      StreamController<InferenceEvent>.broadcast();

  final Random _rng = Random();

  StreamSubscription<Message>? _logSubscription;
  bool _running = false;
  bool _inferencing = false;

  // Queue: when a new message arrives during active inference we set a flag
  // rather than nesting calls.
  bool _pendingResponse = false;

  /// Creates an [InferenceWorker].
  InferenceWorker({
    required this.participant,
    required this.log,
    required this.client,
    required this.hardware,
    required this.contextManager,
  });

  /// Broadcast stream of [InferenceEvent]s produced by this worker.
  Stream<InferenceEvent> get eventStream => _eventController.stream;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Starts the worker, subscribing to [ConversationLog.messageStream].
  ///
  /// [allParticipants] must include this worker's [participant]; it is used
  /// to build the system prompt and context-reset seed participant list.
  void start(List<Participant> allParticipants) {
    if (_running) return;
    _running = true;

    _logSubscription = log.messageStream.listen((message) {
      // Ignore our own messages to avoid self-loops.
      if (message.participantName == participant.name) return;
      if (!_running) return;

      if (_inferencing) {
        // Another inference is already in flight — flag for a follow-up.
        _pendingResponse = true;
      } else {
        _scheduleResponse(allParticipants);
      }
    });
  }

  /// Stops the worker gracefully.
  ///
  /// Any in-flight inference is abandoned; the event stream is closed.
  Future<void> stop() async {
    _running = false;
    await _logSubscription?.cancel();
    _logSubscription = null;
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  // -------------------------------------------------------------------------
  // Core inference loop
  // -------------------------------------------------------------------------

  void _scheduleResponse(List<Participant> allParticipants) {
    // Random jitter: 200–800 ms to stagger AI responses naturally.
    final jitter =
        Duration(milliseconds: 200 + _rng.nextInt(601));

    Timer(jitter, () {
      if (!_running) return;
      _runInference(allParticipants);
    });
  }

  Future<void> _runInference(List<Participant> allParticipants) async {
    if (_inferencing || !_running) return;
    _inferencing = true;

    // Signal "thinking" phase.
    _emit(InferenceEvent(
      participantName: participant.name,
      isThinking: true,
    ));

    try {
      final messages = _buildMessages(allParticipants);
      final numCtx = _contextWindow();

      final responseBuffer = StringBuffer();

      await client.generateStream(
        model: participant.assignedModelId,
        messages: messages,
        numCtx: numCtx,
        onToken: (token) {
          if (!_running) return;
          responseBuffer.write(token);
          _emit(InferenceEvent(
            participantName: participant.name,
            token: token,
          ));
        },
        onDone: () {
          // handled below
        },
        onError: (error) {
          // Swallow errors silently — emit a done event so UI can recover.
        },
      );

      final fullResponse = responseBuffer.toString().trim();
      final isPass = fullResponse.isEmpty;

      // Record token usage (estimate from response length).
      contextManager.recordFromText(participant.name, fullResponse);

      // Append message to shared log.
      final message = Message(
        participantName: participant.name,
        content: fullResponse,
        isUser: false,
      );
      log.append(message);

      _emit(InferenceEvent(
        participantName: participant.name,
        isDone: true,
        isPass: isPass,
      ));
    } catch (_) {
      // Emit done on error so consumers do not hang.
      _emit(InferenceEvent(
        participantName: participant.name,
        isDone: true,
      ));
    } finally {
      _inferencing = false;

      if (_pendingResponse && _running) {
        _pendingResponse = false;
        _scheduleResponse(allParticipants);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Message construction
  // -------------------------------------------------------------------------

  /// Builds the Ollama `messages` payload for the current conversation state.
  ///
  /// If a context reset is needed, only the reset seed is included as history.
  List<Map<String, String>> _buildMessages(
      List<Participant> allParticipants) {
    final systemPrompt = SystemPromptBuilder.build(
      participant,
      allParticipants,
      hardware,
    );

    final numCtx = _contextWindow();
    final needsReset = contextManager.needsReset(participant.name, numCtx);

    List<Message> history;
    if (needsReset) {
      final names = allParticipants.map((p) => p.name).toList();
      // Include "User" as a participant name for the seed.
      if (!names.contains('User')) names.add('User');
      history = contextManager.buildResetSeed(log, names);
      contextManager.reset(participant.name);
      // Re-record the seed token cost.
      for (final m in history) {
        contextManager.recordFromText(participant.name, m.content);
      }
    } else {
      // Use the full log, filtering out passes.
      history = log.allMessages.where((m) => !m.isPass).toList();
    }

    final chatMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final m in history) {
      final role =
          m.participantName == participant.name ? 'assistant' : 'user';
      // Prefix non-user messages with the speaker's name so the model can
      // attribute them in context.
      final prefix =
          m.isUser ? '' : '${m.participantName}: ';
      chatMessages.add({'role': role, 'content': '$prefix${m.content}'});
    }

    return chatMessages;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  int _contextWindow() {
    final isHighCtx = participant.assignedModelId.startsWith('phi3');
    return isHighCtx
        ? hardware.highContextWindow
        : hardware.standardContextWindow;
  }

  void _emit(InferenceEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
}
