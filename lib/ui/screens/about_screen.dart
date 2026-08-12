// Animated About screen for deepThink.
//
// Full-screen Stack:
//   • Bottom layer: NeuralBackgroundPainter (full-screen, continuously animated)
//   • Middle layer: WanderingCharactersLayer (emoji characters in margins)
//   • Top layer:    scrollable content with app title, character bios,
//                   app stats, and system information.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ollama/hardware_detector.dart';
import '../../core/ollama/model_registry.dart';
import '../../core/session/app_stats.dart';
import '../../core/session/session_manager.dart';
import '../about/neural_background_painter.dart';
import '../about/wandering_characters_layer.dart';
import '../avatars/avatar_widget.dart';
import '../avatars/energy_orb/energy_orb_avatar.dart';
import '../widgets/app_theme.dart';

// ---------------------------------------------------------------------------
// AboutScreen
// ---------------------------------------------------------------------------

/// The fully animated About screen — the showpiece of the app.
///
/// All animations run continuously.  Stats are loaded asynchronously.
class AboutScreen extends StatefulWidget {
  /// Pre-detected hardware info.  If null, the screen will detect it itself.
  final HardwareInfo? hardware;

  const AboutScreen({this.hardware, super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _neuralCtrl;
  late final AnimationController _glowCtrl;

  // ── Async data ────────────────────────────────────────────────────────────
  AppStats? _stats;
  HardwareInfo? _hardware;

  @override
  void initState() {
    super.initState();

    // Neural background: 6-second continuous loop.
    _neuralCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // App title glow: 3-second continuous pulse.
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _neuralCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final manager = SessionManager();
    final stats = await manager.loadStats();
    final hw = widget.hardware ?? await HardwareDetector.detect();
    if (mounted) {
      setState(() {
        _stats = stats;
        _hardware = hw;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Layer 1: Neural network background ──────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _neuralCtrl,
              builder: (context, _) => CustomPaint(
                painter: NeuralBackgroundPainter(
                  animationValue: _neuralCtrl.value,
                ),
              ),
            ),
          ),

          // ── Layer 2: Wandering characters ────────────────────────────────
          const Positioned.fill(
            child: WanderingCharactersLayer(),
          ),

          // ── Layer 3: Scrollable content ──────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Close / back button row
                  _CloseBar(),
                  // Scrollable body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── App title ──────────────────────────────
                              _AnimatedTitle(glowCtrl: _glowCtrl),
                              const SizedBox(height: 32),

                              // ── Character bio cards ────────────────────
                              _SectionLabel(label: 'THE TEAM'),
                              const SizedBox(height: 12),
                              const _CharacterBioGrid(),
                              const SizedBox(height: 32),

                              // ── App statistics ─────────────────────────
                              _SectionLabel(label: 'APPLICATION STATISTICS'),
                              const SizedBox(height: 12),
                              _StatsSection(stats: _stats),
                              const SizedBox(height: 32),

                              // ── System information ─────────────────────
                              _SectionLabel(label: 'SYSTEM INFORMATION'),
                              const SizedBox(height: 12),
                              _SystemInfoSection(hardware: _hardware),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CloseBar
// ---------------------------------------------------------------------------

class _CloseBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text(
              'Close',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedTitle
// ---------------------------------------------------------------------------

class _AnimatedTitle extends StatelessWidget {
  final AnimationController glowCtrl;

  const _AnimatedTitle({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (context, _) {
        final glowOpacity =
            0.15 + 0.35 * ((math.sin(glowCtrl.value * math.pi * 2) + 1) / 2);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App name with animated glow
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow halo
                Text(
                  'deepThink',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent.withValues(alpha: glowOpacity),
                    letterSpacing: 5,
                  ),
                ),
                // Crisp foreground text
                const Text(
                  'deepThink',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Version
            const Text(
              'v1.0.1',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'From the minds of Daneyand & IBM\'s Bob',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                letterSpacing: 0.4,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Contact link
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('mailto:daneyand@ibm.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: const Text(
                'daneyand@ibm.com',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionLabel
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CharacterBioGrid — 2×2 grid of character bios
// ---------------------------------------------------------------------------

class _CharacterBioGrid extends StatelessWidget {
  const _CharacterBioGrid();

  static const _bios = [
    (
      name: 'WATSON',
      ibm: 'IBM Watson AI',
      personality: 'The Analyst',
      model: 'gemma2:9b',
    ),
    (
      name: 'DEEP',
      ibm: 'Deep Blue chess computer',
      personality: 'The Host · Strategist',
      model: 'phi3:14b',
    ),
    (
      name: 'NOVA',
      ibm: 'IBM POWER systems',
      personality: 'The Visionary',
      model: 'llama3:8b',
    ),
    (
      name: 'SAGE',
      ibm: 'IBM NL research',
      personality: 'The Challenger',
      model: 'mistral:7b',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 520;

        if (useGrid) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CharacterBioCard(bio: _bios[0])),
                  const SizedBox(width: 12),
                  Expanded(child: _CharacterBioCard(bio: _bios[1])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CharacterBioCard(bio: _bios[2])),
                  const SizedBox(width: 12),
                  Expanded(child: _CharacterBioCard(bio: _bios[3])),
                ],
              ),
            ],
          );
        }

        return Column(
          children: _bios
              .map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CharacterBioCard(bio: b),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _CharacterBioCard extends StatelessWidget {
  final ({
    String name,
    String ibm,
    String personality,
    String model,
  }) bio;

  const _CharacterBioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Orb avatar (48 px, idle state)
          EnergyOrbAvatar(
            state: AvatarState.idle,
            characterName: bio.name,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bio.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bio.ibm,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bio.personality,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                _ModelChip(model: bio.model),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  final String model;

  const _ModelChip({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        model,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatsSection
// ---------------------------------------------------------------------------

class _StatsSection extends StatelessWidget {
  final AppStats? stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Loading…',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final s = stats!;
    return _InfoCard(
      rows: [
        ('Total sessions run', _fmt(s.totalSessionsRun)),
        ('Total messages generated', _fmt(s.totalMessagesGenerated)),
        ('Total tokens processed', _fmt(s.totalTokensProcessed)),
      ],
    );
  }

  static String _fmt(int n) {
    // Format with commas: e.g. 1234567 → "1,234,567"
    final chars = n.toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add(',');
      result.add(chars[i]);
    }
    return result.reversed.join();
  }
}

// ---------------------------------------------------------------------------
// _SystemInfoSection
// ---------------------------------------------------------------------------

class _SystemInfoSection extends StatelessWidget {
  final HardwareInfo? hardware;

  const _SystemInfoSection({required this.hardware});

  @override
  Widget build(BuildContext context) {
    final hw = hardware;
    final totalRam = ModelRegistry.all.fold<double>(0, (s, m) => s + m.ramGb);
    final platform = Platform.isMacOS ? 'macOS' : 'Windows';

    if (hw == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Detecting hardware…',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return _InfoCard(
      rows: [
        (
          'Models installed',
          '${ModelRegistry.all.length} models · '
              '${totalRam.toStringAsFixed(1)} GB total',
        ),
        (
          'Detected hardware',
          '${hw.totalRamGb.toStringAsFixed(0)} GB RAM  ·  '
              '${hw.backendDisplayName}  ·  '
              '${(hw.standardContextWindow / 1024).round()}k ctx',
        ),
        ('Platform', platform),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoCard — generic key/value card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(height: 1, color: AppColors.border),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
