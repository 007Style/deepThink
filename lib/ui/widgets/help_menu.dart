// Help menu widget for deepThink.
//
// Adds a "?" icon button in the top bar on both MainScreen and
// StartupConfigScreen.  Tapping it shows a small popup menu with two items:
//   • "Model Downloads & Installation" → opens ModelHelpScreen
//   • "About deepThink"               → opens AboutScreen
//
// The popup approach works on both macOS and Windows without needing the
// experimental PlatformMenuBar, which has limited cross-platform support.
import 'package:flutter/material.dart';

import '../../core/ollama/hardware_detector.dart';
import '../widgets/app_theme.dart';
import '../screens/about_screen.dart';
import '../screens/model_help_screen.dart';

// ---------------------------------------------------------------------------
// HelpMenuButton
// ---------------------------------------------------------------------------

/// A small "?" icon button that pops up the Help menu.
///
/// Designed to be placed at the trailing end of a top-bar [Row].
/// Pass [hardware] if it has already been detected so the About screen
/// does not need to re-detect it.
class HelpMenuButton extends StatelessWidget {
  /// Pre-detected hardware info.  May be null; About screen will detect it.
  final HardwareInfo? hardware;

  const HelpMenuButton({this.hardware, super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HelpItem>(
      tooltip: 'Help',
      icon: const Icon(
        Icons.help_outline,
        size: 18,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        _menuItem(
          value: _HelpItem.modelInstall,
          icon: Icons.download_outlined,
          label: 'Model Downloads & Installation',
        ),
        _menuItem(
          value: _HelpItem.about,
          icon: Icons.info_outline,
          label: 'About deepThink',
        ),
      ],
      onSelected: (item) => _onSelected(context, item),
    );
  }

  PopupMenuItem<_HelpItem> _menuItem({
    required _HelpItem value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<_HelpItem>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, _HelpItem item) {
    switch (item) {
      case _HelpItem.modelInstall:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ModelHelpScreen(),
          ),
        );
      case _HelpItem.about:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AboutScreen(hardware: hardware),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// _HelpItem
// ---------------------------------------------------------------------------

enum _HelpItem { modelInstall, about }
