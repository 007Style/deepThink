/// Ollama process launcher for deepThink.
///
/// Manages the bundled Ollama binary lifecycle: extraction from Flutter assets
/// (performed at first run since the assets bundle is read-only), starting the
/// background process, and stopping it cleanly on app exit.
///
/// This file has zero Flutter imports — pure Dart only.
/// Path resolution uses [dart:io] and the [path_provider] package is consumed
/// at a higher layer; this class accepts the support directory as a parameter
/// so it remains framework-agnostic.
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
/// final launcher = OllamaLauncher(appSupportDir: '/path/to/app-support');
/// await launcher.start();
/// // ... app runs ...
/// await launcher.stop();
/// ```
///
/// ### Binary extraction
/// Flutter asset bundles are read-only, so the Ollama binary is copied to
/// [appSupportDir] on first run and executed from there.
///
/// **macOS path after extraction:**
/// `~/Library/Application Support/deepThink/ollama`
///
/// **Windows path after extraction:**
/// `%APPDATA%\deepThink\ollama.exe`
class OllamaLauncher {
  /// The app-support directory where the Ollama binary will be extracted.
  ///
  /// Supply the value returned by `getApplicationSupportDirectory()` from
  /// the `path_provider` package (called from the Flutter layer).
  final String appSupportDir;

  /// Base URL for the Ollama REST API.
  final String baseUrl;

  Process? _process;

  /// Creates an [OllamaLauncher].
  ///
  /// [appSupportDir] must be a writable directory on the host OS.
  /// [baseUrl] defaults to `http://localhost:11434`.
  OllamaLauncher({
    required this.appSupportDir,
    this.baseUrl = 'http://localhost:11434',
  });

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
  /// The binary is extracted from the Flutter assets bundle to [appSupportDir]
  /// on first run using [extractBinary].
  ///
  /// Throws a [StateError] if the binary cannot be found or executed.
  Future<void> start() async {
    if (await isRunning()) return;

    final binaryPath = await extractBinary();

    // Ensure the binary is executable on POSIX platforms.
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', binaryPath]);
    }

    _process = await Process.start(
      binaryPath,
      ['serve'],
      environment: {
        ...Platform.environment,
        'OLLAMA_KEEP_ALIVE': '-1',
      },
      mode: ProcessStartMode.detachedWithStdio,
    );

    // Wait up to 10 seconds for the server to become responsive.
    const maxWait = Duration(seconds: 10);
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

  /// Returns the filesystem path to the extracted Ollama binary.
  ///
  /// If the binary is already present in [appSupportDir] this method returns
  /// immediately. Otherwise it reads the raw bytes from the Flutter asset
  /// bundle path (provided via [assetBytesLoader]) and writes them to disk.
  ///
  /// **Note:** Binary extraction from the asset bundle must be triggered from
  /// the Flutter layer because `rootBundle` is a Flutter concept. Pass the
  /// loader via [assetBytesLoader] when calling from Flutter code, or supply
  /// `null` to skip asset extraction (useful when the binary is already present
  /// from a previous run).
  Future<String> extractBinary({
    Future<List<int>> Function(String assetPath)? assetBytesLoader,
  }) async {
    final binaryPath = _binaryPath();
    final file = File(binaryPath);

    if (await file.exists()) return binaryPath;

    // Create the parent directory if needed.
    await file.parent.create(recursive: true);

    if (assetBytesLoader == null) {
      throw StateError(
        'Ollama binary not found at $binaryPath and no assetBytesLoader '
        'was provided for extraction.',
      );
    }

    final assetPath = _assetPath();
    final bytes = await assetBytesLoader(assetPath);
    await file.writeAsBytes(bytes, flush: true);

    return binaryPath;
  }

  // -------------------------------------------------------------------------
  // Path helpers
  // -------------------------------------------------------------------------

  /// The asset-bundle path for the current platform.
  String _assetPath() {
    if (Platform.isWindows) {
      return 'assets/ollama/windows/ollama.exe';
    }
    return 'assets/ollama/macos/ollama';
  }

  /// The filesystem path where the binary is extracted for the current platform.
  String _binaryPath() {
    if (Platform.isWindows) {
      return '$appSupportDir\\deepThink\\ollama.exe';
    }
    return '$appSupportDir/deepThink/ollama';
  }
}
