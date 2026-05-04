import 'package:flutter/material.dart';
import 'screens/lista_mancos_screen.dart';

void main() {
  runApp(const MancosApp());
}

class MancosApp extends StatelessWidget {
  const MancosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Mancos',
      debugShowCheckedModeBanner: false,
      home: const ListaMancosScreen(),
    );
  }
}
