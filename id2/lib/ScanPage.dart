import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Pour les requêtes HTTP
import 'package:image_picker/image_picker.dart'; // Pour sélectionner des fichiers locaux
import 'package:permission_handler/permission_handler.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pour accéder au token stocké

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<String> _pictures = [];
  String _responseMessage = ""; // Stocker la réponse de l'API
  final ImagePicker _picker =
      ImagePicker(); // Instance pour sélectionner des fichiers

  Future<void> _startScan() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        List<String> pictures =
            await CunningDocumentScanner.getPictures() ?? [];
        setState(() {
          _pictures = pictures;
        });

        if (pictures.isNotEmpty) {
          // Envoyer la première image à l'API
          await _sendImageToAPI(File(pictures[0]));
        }
      } catch (e) {
        setState(() {
          _pictures = ['Une erreur s\'est produite : $e'];
        });
      }
    } else {
      setState(() {
        _pictures = [
          'Permission caméra refusée. Veuillez l\'activer dans les paramètres.'
        ];
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _pictures.add(pickedFile.path);
        });

        // Envoyer l'image sélectionnée à l'API
        await _sendImageToAPI(imageFile);
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Erreur lors de la sélection de l'image : $e";
      });
    }
  }

  Future<void> _sendImageToAPI(File imageFile) async {
    final url = Uri.parse('http://192.168.1.2:8080/api/process');

    try {
      // Récupérer le token à partir des SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("Token: $token");

      if (token == null) {
        setState(() {
          _responseMessage = "Token non trouvé. Veuillez vous reconnecter.";
        });
        return;
      }

      // Préparer une requête multipart
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Le nom du paramètre attendu par le backend
          imageFile.path,
        ),
      );

      // Ajouter le token au header de la requête
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      });

      // Envoyer la requête
      var response = await request.send();

      // Traiter la réponse
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        setState(() {
          _responseMessage = "Réponse : $responseBody";
        });
      } else {
        setState(() {
          _responseMessage = "Erreur : ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Échec de l'envoi de l'image : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color customGreen = Color(0xFF8DB581);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _pictures.isNotEmpty
                  ? ListView.builder(
                      itemCount: _pictures.length,
                      itemBuilder: (context, index) {
                        final picture = _pictures[index];
                        if (File(picture).existsSync()) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Image.file(File(picture)),
                          );
                        } else {
                          return Text(
                            picture,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                      },
                    )
                  : const Center(
                      child: Text(
                        "Pas d'images",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: customGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: _startScan,
              child: const Text(
                'Ouvrir la caméra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: _pickImage,
              child: const Text(
                'Uploader une image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Afficher la réponse de l'API
            Text(
              _responseMessage,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
