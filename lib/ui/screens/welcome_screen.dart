// Welcome screen for deepThink.
//
// This is the FIRST thing the user sees after Ollama starts and the model
// check completes. It handles two cases:
//
//   A) Some/all models are MISSING — greet the user, explain what needs to
//      be downloaded, show sizes and locations, ask for confirmation before
//      downloading anything.
//
//   B) All models are PRESENT — greet returning user, show where each model
//      lives on disk, let them go straight to the config screen.
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/ollama/hardware_detector.dart';
import '../../core/ollama/model_manager.dart';
import '../../core/ollama/model_registry.dart';
import '../avatars/avatar_registry.dart';
import '../avatars/avatar_widget.dart';
import '../widgets/app_theme.dart';
import 'first_launch_screen.dart';
import 'startup_config_screen.dart';

// ---------------------------------------------------------------------------
// WelcomeScreen
// ---------------------------------------------------------------------------

/// Greets the user, explains the model situation, and asks before downloading.
class WelcomeScreen extends StatelessWidget {
  final HardwareInfo hardware;
  final List<ModelStatus> modelStatuses;

  const WelcomeScreen({
    required this.hardware,
    required this.modelStatuses,
    super.key,
  });

  bool get _anyMissing => modelStatuses.any((s) => !s.isInstalled);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Logo + greeting ────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 32),

                // ── Hardware summary ───────────────────────────────────────
                _HardwareBar(hardware: hardware),
                const SizedBox(height: 28),

                // ── Model status cards ─────────────────────────────────────
                _buildModelsSection(context),
                const SizedBox(height: 32),

                // ── CTA button ─────────────────────────────────────────────
                _buildCta(context),

                const SizedBox(height: 16),
                _buildFootnote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final greeting = _anyMissing
        ? 'Welcome to deepThink'
        : 'Welcome back to deepThink';

    final subtitle = _anyMissing
        ? 'Four AI minds — one conversation. Before we begin,\n'
          'deepThink needs to download its AI models (~22 GB total).\n'
          'This happens once and the app runs fully offline after that.'
        : 'All four AI models are installed and ready.\n'
          'Your machine is set up and good to go.';

    return Column(
      children: [
        // Orb avatar (DEEP as the host/greeter)
        SizedBox(
          width: 80,
          height: 80,
          child: AvatarRegistry.build(
            'energyOrb',
            state: AvatarState.idle,
            characterName: 'DEEP',
            size: 80,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          greeting,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'v1.0.1',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Models section ───────────────────────────────────────────────────────

  Widget _buildModelsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              _anyMissing ? 'Models to download' : 'Installed models',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (!_anyMissing)
              Text(
                _modelsDir(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // One card per model
        ...modelStatuses.map((s) => _ModelStatusCard(status: s)),
        // Total row
        const SizedBox(height: 8),
        _TotalRamRow(statuses: modelStatuses),
      ],
    );
  }

  // ── CTA button ───────────────────────────────────────────────────────────

  Widget _buildCta(BuildContext context) {
    if (_anyMissing) {
      final missing = modelStatuses.where((s) => !s.isInstalled).length;
      final totalGb = modelStatuses
          .where((s) => !s.isInstalled)
          .fold(0.0, (sum, s) => sum + s.model.ramGb);

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                'Download $missing model${missing == 1 ? '' : 's'} '
                '(~${totalGb.toStringAsFixed(1)} GB) and continue',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _goToDownload(context),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _showManualHelp(context),
            child: const Text(
              'I already have these models — show me where to put them',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text(
            'Configure session and launch',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          onPressed: () => _goToConfig(context),
        ),
      );
    }
  }

  // ── Footnote ─────────────────────────────────────────────────────────────

  Widget _buildFootnote() {
    if (!_anyMissing) return const SizedBox.shrink();
    return const Text(
      'A stable internet connection is required for the download.\n'
      'After that, deepThink runs completely offline — forever.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goToDownload(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FirstLaunchScreen(initialStatuses: modelStatuses),
      ),
    );
  }

  void _goToConfig(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StartupConfigScreen(hardware: hardware),
      ),
    );
  }

  void _showManualHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ManualInstallDialog(modelsDir: _modelsDir()),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the platform-appropriate Ollama models directory path.
  static String _modelsDir() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '~';
      return '$home/.ollama/models/';
    } else {
      final home = Platform.environment['USERPROFILE'] ?? '%USERPROFILE%';
      return '$home\\.ollama\\models\\';
    }
  }
}

// ---------------------------------------------------------------------------
// _HardwareBar
// ---------------------------------------------------------------------------

class _HardwareBar extends StatelessWidget {
  final HardwareInfo hardware;
  const _HardwareBar({required this.hardware});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HardwarePill(
            label: 'RAM',
            value: '${hardware.totalRamGb.toStringAsFixed(0)} GB',
          ),
          _HardwarePill(
            label: 'Inference',
            value: hardware.backendDisplayName,
          ),
          _HardwarePill(
            label: 'Context',
            value: _fmtCtx(hardware.standardContextWindow),
          ),
        ],
      ),
    );
  }

  String _fmtCtx(int tokens) {
    if (tokens >= 1024) return '${(tokens / 1024).round()}K tokens';
    return '$tokens tokens';
  }
}

class _HardwarePill extends StatelessWidget {
  final String label;
  final String value;
  const _HardwarePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ModelStatusCard
// ---------------------------------------------------------------------------

class _ModelStatusCard extends StatelessWidget {
  final ModelStatus status;
  const _ModelStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final installed = status.isInstalled;
    final borderColor = installed
        ? const Color(0xFF1e3a1e)
        : AppColors.border;
    final statusColor = installed
        ? const Color(0xFF4CAF50)
        : AppColors.textSecondary;
    final statusText = installed ? '✓ Installed' : 'Not downloaded';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Model name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.model.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.model.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // RAM size
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~${status.model.ramGb.toStringAsFixed(1)} GB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TotalRamRow
// ---------------------------------------------------------------------------

class _TotalRamRow extends StatelessWidget {
  final List<ModelStatus> statuses;
  const _TotalRamRow({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final totalGb = statuses.fold(0.0, (s, m) => s + m.model.ramGb);
    final missingGb = statuses
        .where((s) => !s.isInstalled)
        .fold(0.0, (s, m) => s + m.model.ramGb);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total stack RAM when all loaded:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            '~${totalGb.toStringAsFixed(1)} GB'
            '${missingGb > 0 ? '  (${missingGb.toStringAsFixed(1)} GB to download)' : ''}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ManualInstallDialog
// ---------------------------------------------------------------------------

class _ManualInstallDialog extends StatelessWidget {
  final String modelsDir;
  const _ManualInstallDialog({required this.modelsDir});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Manual Model Installation',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you already have these models installed via Ollama on '
                'another profile or directory, or you want to install them '
                'manually, here\'s what you need to know:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const _DialogSectionHeader('Step 1 — Install Ollama (if needed)'),
              const _DialogBody(
                'The bundled Ollama engine inside deepThink handles this '
                'automatically. If models are not appearing, open Terminal and run:',
              ),
              _CodeBlock('ollama list'),
              const SizedBox(height: 12),
              const _DialogSectionHeader('Step 2 — Pull missing models'),
              const _DialogBody('Run these commands in Terminal:'),
              ...ModelRegistry.all.map(
                (m) => _CodeBlock('ollama pull ${m.id}'),
              ),
              const SizedBox(height: 12),
              const _DialogSectionHeader('Step 3 — Where models are stored'),
              _CodeBlock(modelsDir),
              const SizedBox(height: 4),
              const _DialogBody(
                'Each model occupies its own subdirectory there. '
                'deepThink reads them automatically on next launch.',
              ),
              const SizedBox(height: 12),
              const _DialogSectionHeader('Step 4 — Verify'),
              _CodeBlock('ollama list'),
              const _DialogBody(
                'You should see all four models listed. Restart deepThink '
                'and it will detect them automatically.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Got it',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _DialogSectionHeader extends StatelessWidget {
  final String text;
  const _DialogSectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
}

class _DialogBody extends StatelessWidget {
  final String text;
  const _DialogBody(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      );
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock(this.code);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFF4a9eff),
          ),
        ),
      );
}
