/// Hardware detection for deepThink.
///
/// Detects total system RAM and GPU type at runtime using [dart:io] subprocess
/// calls. Returns a [HardwareInfo] object used throughout the app to choose
/// the appropriate context window tier and display inference backend status.
///
/// This file has zero Flutter imports — pure Dart only.
library hardware_detector;

import 'dart:io';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Broad RAM capacity tiers that map to Ollama context window sizes.
enum RamTier {
  /// 32 GB machine — smallest context window.
  tier32,

  /// 48 GB machine.
  tier48,

  /// 64 GB machine.
  tier64,

  /// 128 GB or more — largest context window.
  tier128,
}

/// The inference acceleration backend available on this machine.
enum InferenceBackend {
  /// Apple Silicon GPU via Metal (macOS arm64).
  appleMetal,

  /// NVIDIA GPU via CUDA (Windows/Linux).
  cuda,

  /// AMD GPU via ROCm (Windows/Linux).
  rocm,

  /// No discrete GPU — running on CPU only.
  cpu,
}

// ---------------------------------------------------------------------------
// HardwareInfo
// ---------------------------------------------------------------------------

/// Snapshot of the hardware capabilities relevant to Ollama inference.
class HardwareInfo {
  /// Detected total physical RAM in gigabytes.
  final double totalRamGb;

  /// The RAM capacity tier used for context window selection.
  final RamTier ramTier;

  /// The best inference acceleration backend available.
  final InferenceBackend inferenceBackend;

  /// Human-readable backend label for status display
  /// (e.g. `"Apple Metal (GPU)"`).
  final String backendDisplayName;

  /// Returns the Ollama `num_ctx` value for standard models given [ramTier].
  ///
  /// | Tier   | Standard ctx |
  /// |--------|-------------|
  /// | 32 GB  | 8 192       |
  /// | 48 GB  | 16 384      |
  /// | 64 GB  | 32 768      |
  /// | 128 GB | 65 536      |
  int get standardContextWindow {
    switch (ramTier) {
      case RamTier.tier32:
        return 8192;
      case RamTier.tier48:
        return 16384;
      case RamTier.tier64:
        return 32768;
      case RamTier.tier128:
        return 65536;
    }
  }

  /// Returns the Ollama `num_ctx` value for the high-context model (phi3:14b).
  ///
  /// | Tier   | Phi-3 ctx |
  /// |--------|----------|
  /// | 32 GB  | 32 768   |
  /// | 48 GB  | 65 536   |
  /// | 64 GB  | 131 072  |
  /// | 128 GB | 131 072  |
  int get highContextWindow {
    switch (ramTier) {
      case RamTier.tier32:
        return 32768;
      case RamTier.tier48:
        return 65536;
      case RamTier.tier64:
        return 131072;
      case RamTier.tier128:
        return 131072;
    }
  }

  /// Creates a [HardwareInfo] snapshot.
  const HardwareInfo({
    required this.totalRamGb,
    required this.ramTier,
    required this.inferenceBackend,
    required this.backendDisplayName,
  });

  @override
  String toString() =>
      'HardwareInfo(ram=${totalRamGb.toStringAsFixed(1)}GB, '
      'tier=$ramTier, backend=$inferenceBackend)';
}

// ---------------------------------------------------------------------------
// HardwareDetector
// ---------------------------------------------------------------------------

/// Detects system RAM and GPU type at runtime.
///
/// ```dart
/// final info = await HardwareDetector.detect();
/// print(info.backendDisplayName); // "Apple Metal (GPU)"
/// print(info.standardContextWindow); // 32768
/// ```
class HardwareDetector {
  HardwareDetector._();

  /// Detects hardware and returns a [HardwareInfo] snapshot.
  ///
  /// Falls back to safe defaults if any subprocess call fails.
  static Future<HardwareInfo> detect() async {
    final totalRamGb = await _detectRamGb();
    final ramTier = _classifyRam(totalRamGb);
    final backend = await _detectBackend();
    final displayName = _backendDisplayName(backend);

    return HardwareInfo(
      totalRamGb: totalRamGb,
      ramTier: ramTier,
      inferenceBackend: backend,
      backendDisplayName: displayName,
    );
  }

  // -------------------------------------------------------------------------
  // RAM detection
  // -------------------------------------------------------------------------

  static Future<double> _detectRamGb() async {
    try {
      if (Platform.isMacOS) {
        return await _macRamGb();
      } else if (Platform.isWindows) {
        return await _windowsRamGb();
      }
    } catch (_) {
      // Fall through to safe default.
    }
    return 16.0; // conservative fallback
  }

  /// Reads `hw.memsize` from sysctl on macOS.
  static Future<double> _macRamGb() async {
    final result = await Process.run('sysctl', ['hw.memsize']);
    if (result.exitCode != 0) return 16.0;
    final output = (result.stdout as String).trim();
    // Output: "hw.memsize: 34359738368"
    final parts = output.split(':');
    if (parts.length < 2) return 16.0;
    final bytes = int.tryParse(parts[1].trim()) ?? 0;
    return bytes / (1024 * 1024 * 1024);
  }

  /// Reads `TotalPhysicalMemory` via WMIC on Windows.
  static Future<double> _windowsRamGb() async {
    final result = await Process.run(
      'wmic',
      ['ComputerSystem', 'get', 'TotalPhysicalMemory'],
      runInShell: true,
    );
    if (result.exitCode != 0) return 16.0;
    final lines = (result.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    // Lines: ["TotalPhysicalMemory", "34359738368"]
    if (lines.length < 2) return 16.0;
    final bytes = int.tryParse(lines[1]) ?? 0;
    return bytes / (1024 * 1024 * 1024);
  }

  /// Maps a raw GB value to the nearest [RamTier].
  static RamTier _classifyRam(double gb) {
    if (gb >= 112) return RamTier.tier128; // 128 GB machines
    if (gb >= 56) return RamTier.tier64; // 64 GB machines
    if (gb >= 40) return RamTier.tier48; // 48 GB machines
    return RamTier.tier32; // 32 GB and below
  }

  // -------------------------------------------------------------------------
  // GPU / backend detection
  // -------------------------------------------------------------------------

  static Future<InferenceBackend> _detectBackend() async {
    if (Platform.isMacOS) {
      return await _detectMacBackend();
    } else if (Platform.isWindows) {
      return await _detectWindowsBackend();
    }
    return InferenceBackend.cpu;
  }

  /// On macOS, checks whether we are on Apple Silicon (arm64 = Metal).
  static Future<InferenceBackend> _detectMacBackend() async {
    try {
      final result = await Process.run('uname', ['-m']);
      if (result.exitCode == 0) {
        final arch = (result.stdout as String).trim();
        if (arch == 'arm64') return InferenceBackend.appleMetal;
      }
      // Fallback: check CPU brand string for "Apple"
      final sysctl =
          await Process.run('sysctl', ['machdep.cpu.brand_string']);
      if (sysctl.exitCode == 0) {
        final brand = (sysctl.stdout as String).toLowerCase();
        if (brand.contains('apple')) return InferenceBackend.appleMetal;
      }
    } catch (_) {
      // Ignore — return cpu below.
    }
    return InferenceBackend.cpu;
  }

  /// On Windows, tries nvidia-smi (CUDA) then rocminfo (ROCm).
  static Future<InferenceBackend> _detectWindowsBackend() async {
    // Check CUDA via nvidia-smi
    try {
      final nvResult = await Process.run(
        'nvidia-smi',
        [],
        runInShell: true,
      );
      if (nvResult.exitCode == 0) return InferenceBackend.cuda;
    } catch (_) {}

    // Check ROCm via rocminfo
    try {
      final rocmResult = await Process.run(
        'rocminfo',
        [],
        runInShell: true,
      );
      if (rocmResult.exitCode == 0) return InferenceBackend.rocm;
    } catch (_) {}

    return InferenceBackend.cpu;
  }

  static String _backendDisplayName(InferenceBackend backend) {
    switch (backend) {
      case InferenceBackend.appleMetal:
        return 'Apple Metal (GPU)';
      case InferenceBackend.cuda:
        return 'NVIDIA CUDA (GPU)';
      case InferenceBackend.rocm:
        return 'AMD ROCm (GPU)';
      case InferenceBackend.cpu:
        return 'CPU (no GPU acceleration)';
    }
  }
}
