import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: OcrPage()));


class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final _picker = ImagePicker();

  // Reconocedor de ML Kit (alfabeto latino: español, inglés, etc.)
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _imagen;
  String _texto = '';
  String _datos = '';
  bool _cargando = false;

  Future<void> _leerTexto(ImageSource origen) async {
    // 1. Tomar la foto o elegirla de la galería
    final foto = await _picker.pickImage(source: origen);
    if (foto == null) return; // el usuario canceló

    setState(() {
      _imagen = File(foto.path);
      _cargando = true;
    });

    // 2. Convertir la imagen al formato que entiende ML Kit
    final input = InputImage.fromFilePath(foto.path);

    // 3. Procesar la imagen en el celular, sin internet
    final resultado = await _recognizer.processImage(input);

    // 4. Mostrar el texto y los datos detectados
    setState(() {
      _texto = resultado.text.isEmpty ? 'No se encontró texto' : resultado.text;
      _datos = _extraerDatos(resultado.text);
      _cargando = false;
    });
  }

  // Caso de uso: buscar correos, celulares y valores dentro del texto
  String _extraerDatos(String texto) {
    final correos = RegExp(r'[\w.\-]+@[\w\-]+\.[\w.]+').allMatches(texto);
    final celulares = RegExp(r'3\d{2}[\s-]?\d{3}[\s-]?\d{4}').allMatches(texto);
    final valores = RegExp(r'\$\s?[\d.,]+').allMatches(texto);

    final lineas = <String>[
      ...correos.map((m) => 'Correo: ${m.group(0)}'),
      ...celulares.map((m) => 'Celular: ${m.group(0)}'),
      ...valores.map((m) => 'Valor: ${m.group(0)}'),
    ];
    return lineas.join('\n');
  }

  @override
  void dispose() {
    _recognizer.close(); // 5. Liberar el modelo de la memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR con ML Kit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Botones de cámara y galería
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

          // Círculo de carga mientras ML Kit procesa; luego el texto
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else
            SelectableText(_texto),

          // Solo aparece si se encontraron datos útiles
          if (_datos.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Datos detectados:\n$_datos'),
              ),
            ),
        ],
      ),
    );
  }
}