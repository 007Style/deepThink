// Main application screen for deepThink.
//
// Assembles: top header bar, 2×2 quadrant grid, user input bar, status band.
// Manages ConversationEngine lifecycle, routes InferenceEvents to quadrants,
// and tracks user-name easter-egg updates.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/conversation/conversation_engine.dart';
import '../../core/conversation/inference_worker.dart';
import '../../core/conversation/message.dart';
import '../../core/conversation/participant.dart';
import '../../core/conversation/user_name_detector.dart';
import '../../core/ollama/hardware_detector.dart';
import '../../core/ollama/ollama_client.dart';
import '../../core/session/session.dart';
import '../../core/session/session_manager.dart';
import '../avatars/avatar_widget.dart';
import '../quadrants/quadrant_grid.dart';
import '../widgets/app_theme.dart';
import '../widgets/help_menu.dart';
import '../widgets/start_stop_button.dart';
import '../widgets/status_band.dart';
import '../widgets/user_input_bar.dart';

// ---------------------------------------------------------------------------
// MainScreen
// ---------------------------------------------------------------------------

/// The primary application window, shown once startup configuration is done.
///
/// Accepts:
/// - [participants] — the four configured [Participant] objects.
/// - [hardware]     — detected [HardwareInfo] for display and context sizing.
class MainScreen extends StatefulWidget {
  /// The four AI participants to display.
  final List<Participant> participants;

  /// Detected hardware info (RAM tier, backend).
  final HardwareInfo hardware;

  const MainScreen({
    required this.participants,
    required this.hardware,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// ---------------------------------------------------------------------------
// _QuadrantState — per-participant mutable state
// ---------------------------------------------------------------------------

class _QuadrantState {
  final List<Message> messages = [];
  AvatarState avatarState = AvatarState.idle;
  bool isThinking = false;

  // Each quadrant gets its own broadcast StreamController for live tokens.
  final StreamController<String> tokenController =
      StreamController<String>.broadcast();

  Stream<String> get tokenStream => tokenController.stream;

  void dispose() {
    tokenController.close();
  }
}

// ---------------------------------------------------------------------------
// _MainScreenState
// ---------------------------------------------------------------------------

class _MainScreenState extends State<MainScreen> {
  // Core
  late final ConversationEngine _engine;
  late final SessionManager _sessionManager;
  Session? _session;
  StreamSubscription<InferenceEvent>? _engineSub;
  StreamSubscription<Message>? _logSub;

  // UI state
  bool _isRunning = false;
  String _userName = 'User';
  String _sessionName = '';

  // One _QuadrantState per participant (keyed by participant name).
  final Map<String, _QuadrantState> _quadrantStates = {};

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Initialise the Ollama client. It connects to localhost:11434 by default.
    _engine = ConversationEngine(
      client: OllamaClient(),
    );
    _sessionManager = SessionManager();

    for (final p in widget.participants) {
      _quadrantStates[p.name] = _QuadrantState();
    }
  }

  @override
  void dispose() {
    _stop();
    for (final qs in _quadrantStates.values) {
      qs.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Start / Stop
  // -------------------------------------------------------------------------

  Future<void> _start() async {
    if (_isRunning) return;

    // Create and start the session.
    final session = await _sessionManager.createSession(
      participants: widget.participants,
    );
    _session = session;

    // Start the engine and begin logging.
    await _engine.start(widget.participants, widget.hardware);

    _logSub = await _sessionManager.startLogging(
      session,
      _engine.log.messageStream,
    );

    // Subscribe to inference events and route them to quadrants.
    _engineSub = _engine.eventStream.listen(_handleEvent);

    // Also listen to the log for completed messages (for all quadrants).
    _engine.log.messageStream.listen(_handleLogMessage);

    setState(() {
      _isRunning = true;
      _sessionName = session.name;
    });
  }

  Future<void> _stop() async {
    if (!_isRunning) return;

    await _engineSub?.cancel();
    _engineSub = null;

    await _engine.stop();

    if (_session != null) {
      await _sessionManager.endSession(_session!);
      _session = null;
    }

    await _logSub?.cancel();
    _logSub = null;

    // Reset quadrant states.
    for (final qs in _quadrantStates.values) {
      qs.avatarState = AvatarState.idle;
      qs.isThinking = false;
    }

    if (mounted) {
      setState(() => _isRunning = false);
    }
  }

  // -------------------------------------------------------------------------
  // Event routing
  // -------------------------------------------------------------------------

  void _handleEvent(InferenceEvent event) {
    final qs = _quadrantStates[event.participantName];
    if (qs == null) return;

    if (event.isThinking) {
      setState(() {
        qs.avatarState = AvatarState.thinking;
        qs.isThinking = true;
      });
      return;
    }

    if (event.token != null) {
      // Stream token to the quadrant's live text area.
      qs.tokenController.add(event.token!);
      if (qs.avatarState != AvatarState.speaking) {
        setState(() => qs.avatarState = AvatarState.speaking);
      }

      // Run user-name detection on every token batch.
      final newName = UserNameDetector.detectRename(event.token!, _userName);
      if (newName != null && mounted) {
        setState(() => _userName = newName);
      }
      return;
    }

    if (event.isDone) {
      setState(() {
        qs.avatarState = AvatarState.idle;
        qs.isThinking = false;
      });
    }
  }

  void _handleLogMessage(Message msg) {
    if (!mounted) return;
    // Append each completed, non-pass message to ALL quadrants so every panel
    // shows the full conversation.
    if (msg.isPass) return;
    setState(() {
      for (final qs in _quadrantStates.values) {
        qs.messages.add(msg);
      }
    });
  }

  // -------------------------------------------------------------------------
  // User input
  // -------------------------------------------------------------------------

  void _onUserSubmit(String text) {
    _engine.injectUserMessage(_userName, text);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final quadrantDataList = widget.participants.map((p) {
      final qs = _quadrantStates[p.name]!;
      return QuadrantData(
        participant: p,
        messages: List.unmodifiable(qs.messages),
        avatarState: qs.avatarState,
        isThinking: qs.isThinking,
        tokenStream: qs.tokenStream,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top header bar ────────────────────────────────────────────────
          _TopBar(
            isRunning: _isRunning,
            sessionName: _sessionName,
            onStart: _start,
            onStop: _stop,
            hardware: widget.hardware,
          ),
          // ── Quadrant grid ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: QuadrantGrid(quadrants: quadrantDataList),
            ),
          ),
          // ── User input bar ────────────────────────────────────────────────
          UserInputBar(
            userName: _userName,
            enabled: _isRunning,
            onSubmit: _onUserSubmit,
          ),
          // ── Status band ───────────────────────────────────────────────────
          StatusBand(
            hardware: widget.hardware,
            sessionName: _sessionName,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TopBar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final bool isRunning;
  final String sessionName;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final HardwareInfo hardware;

  const _TopBar({
    required this.isRunning,
    required this.sessionName,
    required this.onStart,
    required this.onStop,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // App name — left
          const Text(
            'deepThink',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 1.2,
            ),
          ),
          // Start/Stop — centre
          const Spacer(),
          StartStopButton(
            isRunning: isRunning,
            onStart: onStart,
            onStop: onStop,
          ),
          // Session name + help button — right
          const Spacer(),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                sessionName.isNotEmpty ? 'Session: $sessionName' : '',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          HelpMenuButton(hardware: hardware),
        ],
      ),
    );
  }
}
