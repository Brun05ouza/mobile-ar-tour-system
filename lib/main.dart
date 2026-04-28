import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/deep_link.dart';
import 'app/theme/app_theme.dart';
import 'data/models/point_model.dart';
import 'data/services/user_prefs_service.dart';
import 'features/recognition/presentation/hybrid_ar_view.dart';
import 'presentation/ar/ar_view.dart';
import 'presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PointModelAdapter());
  await Hive.openBox<PointModel>('points');
  await UserPrefsService.openBoxes();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();

  DeepLinkTarget _bootTarget = DeepLinkTarget.home;
  bool _ready = false;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _resolveInitialLink();
  }

  Future<void> _resolveInitialLink() async {
    Uri? initial;
    try {
      initial = await _appLinks.getInitialLink();
    } catch (_) {
      initial = null;
    }
    if (!mounted) return;
    setState(() {
      _bootTarget = parseDeepLink(initial);
      _ready = true;
    });

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      final route = initialRouteFromTarget(parseDeepLink(uri));
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        route,
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppGradients.background),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: initialRouteFromTarget(_bootTarget),
      routes: {
        '/': (_) => const HomeScreen(),
        '/hybrid': (_) => const HybridArView(),
        '/ar': (_) => const ArView(),
      },
    );
  }
}
