import 'package:flutter/material.dart';

void main() {
  runApp(const ReadingSanctuaryApp());
}

class ReadingSanctuaryApp extends StatelessWidget {
  const ReadingSanctuaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading Sanctuary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to Reading Sanctuary'),
        ),
      ),
    );
  }
}
