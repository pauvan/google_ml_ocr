import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(const MaterialApp(home: OcrPage()));

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _imagen;
  String _texto = '';
  bool _cargando = false;

  Future<void> _leerTexto(ImageSource origen) async {
    final foto = await _picker.pickImage(source: origen);
    if (foto == null) return;

    setState(() {
      _imagen = File(foto.path);
      _cargando = true;
    });

    final input = InputImage.fromFilePath(foto.path);
    final resultado = await _recognizer.processImage(input);

    setState(() {
      _texto = resultado.text.isEmpty ? 'No se encontró texto' : resultado.text;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR con ML Kit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _leerTexto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _leerTexto(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_imagen != null) Image.file(_imagen!, height: 250),
          const SizedBox(height: 16),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else
            SelectableText(_texto),
        ],
      ),
    );
  }
}