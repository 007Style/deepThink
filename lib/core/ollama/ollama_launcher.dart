/// Ollama process launcher for deepThink.
///
/// Manages the bundled Ollama binary lifecycle. On macOS the full Ollama
/// runtime is copied into the .app bundle at build time by the Xcode
/// "Copy Ollama Runtime" shell-script build phase and lives at:
///
///   `<app>.app/Contents/Resources/ollama/ollama`
///
/// On Windows the runtime is placed next to the executable under:
///
///   `<install dir>\ollama\ollama.exe`
///
/// This file has zero Flutter imports — pure Dart only.
library ollama_launcher;

import 'dart:io';
import 'dart:async';

// ---------------------------------------------------------------------------
// OllamaLauncher
// ---------------------------------------------------------------------------

/// Manages the lifecycle of the bundled Ollama background process.
///
/// ### Typical usage
/// ```dart
/// final launcher = OllamaLauncher();
/// await launcher.start();
/// // ... app runs ...
/// await launcher.stop();
/// ```
///
/// ### Binary location
/// The binary is **not** extracted from Flutter assets — it is bundled
/// directly into the native app package at build time:
///
/// - **macOS:** `<app>.app/Contents/Resources/ollama/ollama`
///   (copied by the Xcode "Copy Ollama Runtime" build phase)
/// - **Windows:** `<exe dir>\ollama\ollama.exe`
///   (placed there by the NSIS/Inno Setup installer)
class OllamaLauncher {
  /// Base URL for the Ollama REST API.
  final String baseUrl;

  Process? _process;

  /// Creates an [OllamaLauncher].
  ///
  /// [baseUrl] defaults to `http://localhost:11434`.
  OllamaLauncher({this.baseUrl = 'http://localhost:11434'});

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns `true` if the Ollama HTTP server is responding on [baseUrl].
  Future<bool> isRunning() async {
    try {
      final uri = Uri.parse(baseUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain<void>();
      client.close();
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Starts the Ollama background process.
  ///
  /// If Ollama is already running (detected via [isRunning]) this method
  /// returns immediately without spawning a second process.
  ///
  /// Throws a [StateError] if the binary cannot be found or executed.
  Future<void> start() async {
    if (await isRunning()) return;

    final binaryPath = _binaryPath();
    final file = File(binaryPath);
    if (!await file.exists()) {
      throw StateError(
        'Bundled Ollama binary not found at "$binaryPath".\n'
        'Ensure the "Copy Ollama Runtime" Xcode build phase ran successfully.',
      );
    }

    // Ensure executable bit is set (may be lost during packaging on some systems).
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', binaryPath]);
    }

    // Also chmod the helper binaries in the same directory.
    if (Platform.isMacOS) {
      final dir = file.parent;
      for (final name in ['llama-server', 'llama-quantize']) {
        final helper = File('${dir.path}/$name');
        if (await helper.exists()) {
          await Process.run('chmod', ['+x', helper.path]);
        }
      }
    }

    _process = await Process.start(
      binaryPath,
      ['serve'],
      environment: {
        ...Platform.environment,
        'OLLAMA_KEEP_ALIVE': '-1',
        // Tell Ollama where its own binaries live (same directory).
        'OLLAMA_RUNNERS_DIR': file.parent.path,
      },
      mode: ProcessStartMode.detachedWithStdio,
    );

    // Wait up to 15 seconds for the server to become responsive.
    const maxWait = Duration(seconds: 15);
    const pollInterval = Duration(milliseconds: 300);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      if (await isRunning()) return;
      await Future<void>.delayed(pollInterval);
    }

    throw StateError(
      'Ollama process started but server did not respond within '
      '${maxWait.inSeconds}s at $baseUrl',
    );
  }

  /// Stops the managed Ollama process if one was started by this instance.
  ///
  /// Has no effect if Ollama was already running externally before [start]
  /// was called.
  Future<void> stop() async {
    _process?.kill();
    _process = null;
  }

  // -------------------------------------------------------------------------
  // Path helpers
  // -------------------------------------------------------------------------

  /// Returns the filesystem path to the bundled Ollama binary.
  ///
  /// - macOS: resolved relative to the running executable inside the .app bundle.
  /// - Windows: resolved relative to the running executable.
  String _binaryPath() {
    if (Platform.isMacOS) {
      // Executable path: <app>.app/Contents/MacOS/deep_think
      // Binary path:     <app>.app/Contents/Resources/ollama/ollama
      final exeDir = File(Platform.resolvedExecutable).parent;
      // Go up from MacOS/ to Contents/, then into Resources/ollama/
      final contentsDir = exeDir.parent;
      return '${contentsDir.path}/Resources/ollama/ollama';
    } else if (Platform.isWindows) {
      // Executable path: <install dir>\deep_think.exe
      // Binary path:     <install dir>\ollama\ollama.exe
      final exeDir = File(Platform.resolvedExecutable).parent;
      return '${exeDir.path}\\ollama\\ollama.exe';
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}
