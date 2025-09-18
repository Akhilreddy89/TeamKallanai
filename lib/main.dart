import 'package:flutter/material.dart';
import 'views/input_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rainwater Harvesting Feasibility App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const InputPage(),
    );
  }
}
