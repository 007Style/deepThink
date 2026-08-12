// deepThink entry point.
//
// Startup flow:
//   1. Show splash/loading screen while hardware detection + model checks run.
//   2. If any models missing  → FirstLaunchScreen (download them).
//   3. If all models present  → StartupConfigScreen (configure & launch).
import 'package:flutter/material.dart';

import 'core/ollama/hardware_detector.dart';
import 'core/ollama/model_manager.dart';
import 'core/ollama/ollama_client.dart';
import 'ui/avatars/avatar_registry.dart';
import 'ui/screens/first_launch_screen.dart';
import 'ui/screens/startup_config_screen.dart';
import 'ui/widgets/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register built-in avatar types before the widget tree is built.
  AvatarRegistry.registerDefaults();

  runApp(const DeepThinkApp());
}

// ---------------------------------------------------------------------------
// DeepThinkApp
// ---------------------------------------------------------------------------

class DeepThinkApp extends StatelessWidget {
  const DeepThinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'deepThink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppLoader(),
    );
  }
}

// ---------------------------------------------------------------------------
// _AppLoader — detects hardware + checks models, then routes to the right screen
// ---------------------------------------------------------------------------

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _loading = true;
  HardwareInfo? _hardware;
  List<ModelStatus>? _modelStatuses;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Run hardware detection and model check concurrently.
    final results = await Future.wait([
      HardwareDetector.detect(),
      ModelManager(client: OllamaClient()).checkModels(),
    ]);

    if (!mounted) return;
    setState(() {
      _hardware = results[0] as HardwareInfo;
      _modelStatuses = results[1] as List<ModelStatus>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Splash / loading ────────────────────────────────────────────────────
    if (_loading) {
      return const _SplashScreen();
    }

    final statuses = _modelStatuses!;
    final hardware = _hardware!;
    final anyMissing = statuses.any((s) => !s.isInstalled);

    // ── First launch — download missing models ───────────────────────────────
    if (anyMissing) {
      return FirstLaunchScreen(initialStatuses: statuses);
    }

    // ── All models present — jump straight to config ─────────────────────────
    return StartupConfigScreen(hardware: hardware);
  }
}

// ---------------------------------------------------------------------------
// _SplashScreen
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'deepThink',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
