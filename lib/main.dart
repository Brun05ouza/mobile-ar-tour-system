import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/point_model.dart';
import 'data/services/user_prefs_service.dart';
import 'presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PointModelAdapter());
  await Hive.openBox<PointModel>('points');
  await UserPrefsService.openBoxes();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Tour',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}

// ── Tema centralizado ─────────────────────────────────────────────────────────

abstract final class AppTheme {
  static const Color bg = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D26);
  static const Color primary = Color(0xFF00BFA5);     // tealAccent
  static const Color secondary = Color(0xFF5C6BC0);   // indigo
  static const Color accent = Color(0xFFFF4081);      // pinkAccent
  static const Color success = Color(0xFF66BB6A);     // green
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0x99FFFFFF); // white60

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: surface,
          contentTextStyle: const TextStyle(color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: primary),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(
              color: textSecondary, fontSize: 14, height: 1.4),
          labelSmall: TextStyle(
              color: textSecondary, fontSize: 11, letterSpacing: 1.0),
        ),
      );
}
