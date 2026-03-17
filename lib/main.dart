import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/point_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa banco local
  await Hive.initFlutter();
  Hive.registerAdapter(PointModelAdapter());
  await Hive.openBox<PointModel>('points');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Tour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            '🚀 AR Tour funcionando!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}