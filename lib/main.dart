import 'package:crop_diseases/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'Flutter Deep learning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(color: Colors.deepPurple[100]),
      ),
      home: const HomeScreen(),
    );
  }
}
