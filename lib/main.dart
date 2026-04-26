import 'package:flutter/material.dart';
import 'package:manutencao_veiculos/views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Importante para o SQLite
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Manutenção',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeView(),
    );
  }
}