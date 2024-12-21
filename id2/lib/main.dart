
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:id2/ScanPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner',
      debugShowCheckedModeBanner: false, // Remove the Debug badge
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Timer to navigate to ScanPage after 7 seconds
    Timer(const Duration(seconds: 7), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add the image asset here
            Image(
              image: AssetImage('assert/SCANNE.png'),
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
  "Bienvenue dans le Scanner d'Identité",
  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
),
            SizedBox(height: 20),
            CircularProgressIndicator(), // Loading indicator
          ],
        ),
      ),
    );
  }
}
