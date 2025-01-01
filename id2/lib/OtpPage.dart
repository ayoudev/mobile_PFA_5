import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:id2/ScanPage.dart';

class OtpPage extends StatefulWidget {
  final String email;

  OtpPage({required this.email});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  late Timer _timer;
  int _timeLeft = 30; // Temps en secondes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('L\'OTP a expiré. Veuillez en demander un nouveau.')),
          );
        }
      });
    });
  }

  void _verifyOtp(BuildContext context) async {
    if (_timeLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP expiré. Veuillez en demander un nouveau.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:8080/api/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: ({'email': widget.email, 'otp': _otpController.text}),
      );

      if (response.statusCode == 200) {
        // Naviguer vers ScanPage après vérification réussie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ScanPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP invalide.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion. Veuillez réessayer.')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vérification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Un OTP a été envoyé à ${widget.email}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Entrez l\'OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Text(
              'Temps restant : $_timeLeft secondes',
              style: TextStyle(color: _timeLeft > 0 ? Colors.black : Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _timeLeft > 0 ? () => _verifyOtp(context) : null,
              child: Text('Vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}
