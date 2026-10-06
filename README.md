# OCR local en Flutter con Google ML Kit

App de ejemplo en Flutter que toma una foto (o la elige de la galería) y **extrae el texto** que aparece en ella usando **Google ML Kit**, todo dentro del celular y **sin internet**.

Este repositorio acompaña un taller práctico: puedes seguir la guía paso a paso o clonar el proyecto y ejecutarlo directamente.

**Paquete principal:** [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition)

---

## Tabla de contenido


- [Requisitos](#requisitos)
- [¿Qué es Google ML Kit?] (#¿Qué es Google ML Kit?)
- [Ejecutar este repositorio](#ejecutar-este-repositorio)
- [Guía paso a paso](#guía-paso-a-paso)
  - [Paso 0: Preparar el entorno](#paso-0-preparar-el-entorno)
  - [Paso 1: Crear el proyecto](#paso-1-crear-el-proyecto)
  - [Paso 2: Instalar los paquetes](#paso-2-instalar-los-paquetes)
  - [Paso 3: Configurar Android (y iOS si aplica)](#paso-3-configurar-android-y-ios-si-aplica)
  - [Paso 4: Preparar la pantalla](#paso-4-preparar-la-pantalla)
  - [Paso 5: La función que lee el texto](#paso-5-la-función-que-lee-el-texto)
  - [Paso 6: Construir la interfaz](#paso-6-construir-la-interfaz)
  - [Paso 7: Ejecutar y probar](#paso-7-ejecutar-y-probar)
- [Código final completo](#código-final-completo-libmaindart)
- [Errores comunes](#errores-comunes)
- [Retos opcionales](#retos-opcionales)

---

## Requisitos

- [ ] Flutter instalado y funcionando (`flutter doctor` sin errores en Android)
- [ ] Un **celular Android físico** y un cable USB de datos
- [ ] Un editor (VS Code o Android Studio) con el plugin de Flutter
- [ ] Una hoja con texto impreso (letra grande) para hacer pruebas

> **Importante:** ML Kit solo funciona en Android e iOS. No sirve en Chrome, Windows ni Linux, así que no ejecutes el proyecto en esas plataformas.

---

## ¿Qué es Google ML Kit?

**ML Kit** es el kit de Google para usar machine learning dentro de apps móviles. Trae modelos ya entrenados para tareas comunes como reconocer texto (OCR), leer códigos de barras o etiquetar imágenes.

### ¿Qué significa "procesamiento local"?

El modelo viene dentro de la app y corre en el procesador del celular. Eso trae tres ventajas:

- **Funciona sin internet:** no depende de un servidor.
- **Privacidad:** la imagen nunca sale del dispositivo.
- **Rapidez:** no hay espera de red; el resultado sale en fracciones de segundo.

La desventaja es que la app pesa un poco más y la precisión depende de la calidad de la foto (luz, enfoque, ángulo).

### El patrón de ML Kit

1. Consigues una imagen (cámara o galería).
2. La conviertes en un `InputImage`.
3. Se la pasas al reconocedor (`TextRecognizer`).
4. Recibes un resultado con el texto encontrado.
5. Cierras el reconocedor cuando ya no lo usas.

### Cómo organiza el texto reconocido (`RecognizedText`)

- `text`: todo el texto junto en un solo String.
- `blocks`: bloques, parecidos a párrafos.
- Cada bloque tiene `lines` (líneas), y cada línea tiene `elements` (palabras).
- Todos traen su posición en la imagen (`boundingBox`), útil si quieres dibujar recuadros encima.

---

## Ejecutar este repositorio

Si solo quieres probar la app terminada:

```bash
git clone <URL-de-este-repositorio>
cd ocr_demo
flutter pub get
flutter run
```

Conecta antes tu celular por USB (ver [Paso 0](#paso-0-preparar-el-entorno)).

---

## Guía paso a paso

### Paso 0: Preparar el entorno

#### 0.1 Verificar Flutter

Abre una terminal (CMD, PowerShell o la terminal de VS Code) y ejecuta:

```bash
flutter --version
flutter doctor
```

En el resultado de `flutter doctor` deben aparecer con check verde por lo menos **Flutter**, **Android toolchain** y **Android Studio**. Si Android toolchain marca error de licencias, ejecuta:

```bash
flutter doctor --android-licenses
```

y acepta todo escribiendo `y`. Las marcas de Chrome, Visual Studio o Xcode se pueden ignorar en este taller.

#### 0.2 Conectar el celular por cable USB

1. En el celular, ve a **Ajustes → Acerca del teléfono** y toca **Número de compilación** 7 veces hasta que diga "Ya eres desarrollador". En Xiaomi está en **Versión de MIUI/HyperOS**; en Samsung, dentro de **Información de software**.
2. Vuelve a **Ajustes → Sistema → Opciones de desarrollador** y activa **Depuración USB**. En Xiaomi activa también **Instalar vía USB**.
3. Conecta el celular al PC con un cable de **datos** (algunos cables solo cargan).
4. En el celular aparecerá "¿Permitir depuración USB?": marca **Permitir siempre** y acepta.
5. Comprueba que el PC lo detecta:

```bash
flutter devices
```

Debe aparecer tu celular en la lista, por ejemplo:

```
SM A145M (mobile) • R58T... • android-arm64
```

#### 0.3 Seleccionar el celular en VS Code

En la esquina **inferior derecha** de VS Code aparece el dispositivo activo (por ejemplo "Windows (windows-x64)" o "Chrome"). Haz clic ahí y elige tu **celular Android**. También puedes usar `Ctrl + Shift + P` → **Flutter: Select Device**.

Si trabajas solo desde la terminal, usa el id que muestra `flutter devices`:

```bash
flutter run -d R58T1234ABC
```

(Reemplaza `R58T1234ABC` por el id que aparece en tu lista.)

---

### Paso 1: Crear el proyecto

Abre una terminal en la carpeta donde guardas tus proyectos y ejecuta:

```bash
flutter create ocr_demo
cd ocr_demo
```

**Alternativa desde VS Code:** `Ctrl + Shift + P` → **Flutter: New Project** → **Application** → elige la carpeta → escribe el nombre `ocr_demo` → Enter. VS Code abre el proyecto solo.

> El nombre del proyecto debe ir en minúsculas y con guion bajo, sin espacios ni tildes.

Abre la carpeta `ocr_demo` en tu editor.

---

### Paso 2: Instalar los paquetes

Necesitamos dos paquetes: el de ML Kit para reconocer texto y `image_picker` para tomar fotos o elegirlas de la galería.

```bash
flutter pub add google_mlkit_text_recognition image_picker
```

Revisa que en tu `pubspec.yaml`, dentro de `dependencies:`, aparezcan ambos paquetes con su versión. Este comando ya ejecuta `flutter pub get` por ti; si no, ejecútalo manualmente.

---

### Paso 3: Configurar Android (y iOS si aplica)

#### Android

ML Kit necesita Android 5.0 (API 21) o superior. Abre el archivo de configuración de la app:

- Proyectos nuevos: `android/app/build.gradle.kts`
- Proyectos antiguos: `android/app/build.gradle`

Busca el bloque `defaultConfig` y revisa el valor mínimo de SDK. Si dice `flutter.minSdkVersion`, normalmente ya cumple; si te da error al compilar, cámbialo por 21 o más:

```kotlin
// build.gradle.kts
defaultConfig {
    minSdk = 21
}
```

```groovy
// build.gradle (versión antigua)
defaultConfig {
    minSdkVersion 21
}
```

Para Android, `image_picker` no necesita permisos extra en el `AndroidManifest.xml`.

#### iOS (solo si alguien usa iPhone y Mac)

1. En `ios/Podfile`, descomenta o agrega la línea `platform :ios, '15.5'`.
2. En `ios/Runner/Info.plist`, dentro de `<dict>`, agrega los permisos de cámara y galería:

```xml
<key>NSCameraUsageDescription</key>
<string>La app usa la cámara para leer texto</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La app usa la galería para leer texto</string>
```

En iOS conviene probar en un iPhone físico; el simulador puede fallar con ML Kit.

---

### Paso 4: Preparar la pantalla

Abre `lib/main.dart`, **borra todo** su contenido y pega esta base. Es una pantalla vacía con las variables que vamos a usar:

```dart
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

  File? _imagen;          // la foto elegida
  String _texto = '';     // el texto reconocido
  bool _cargando = false; // para mostrar un indicador

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Aquí irá la UI')));
  }
}
```

`TextRecognitionScript.latin` sirve para español e inglés. Existen otros alfabetos (chino, japonés, coreano, devanagari) que requieren paquetes adicionales.

---

### Paso 5: La función que lee el texto

Este es el corazón del taller. Pégala dentro de `_OcrPageState`, encima de `build`:

```dart
Future<void> _leerTexto(ImageSource origen) async {
  // 1. Conseguir la imagen
  final foto = await _picker.pickImage(source: origen);
  if (foto == null) return; // el usuario canceló

  setState(() {
    _imagen = File(foto.path);
    _cargando = true;
  });

  // 2. Convertirla en InputImage
  final input = InputImage.fromFilePath(foto.path);

  // 3. Procesarla con ML Kit (todo local)
  final resultado = await _recognizer.processImage(input);

  // 4. Mostrar el resultado
  setState(() {
    _texto = resultado.text.isEmpty ? 'No se encontró texto' : resultado.text;
    _cargando = false;
  });
}

@override
void dispose() {
  _recognizer.close(); // 5. Liberar el modelo
  super.dispose();
}
```

Fíjate en que los números de los comentarios son los mismos 5 pasos de la teoría.

---

### Paso 6: Construir la interfaz

Reemplaza el método `build` por este:

```dart
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
```

Usamos `SelectableText` para que el texto se pueda seleccionar y copiar sin programar nada extra.

---

### Paso 7: Ejecutar y probar

1. Verifica que el dispositivo seleccionado (esquina inferior derecha de VS Code) sea tu celular Android, no Chrome ni Windows.
2. Ejecuta la app con **F5** (o **Run → Start Debugging**), o desde la terminal:

   ```bash
   flutter run
   ```

3. La primera compilación puede tardar entre 3 y 10 minutos, porque Gradle descarga las dependencias de ML Kit. Necesitas internet solo esta vez.
4. Cuando abra la app, prueba **Galería** primero con una imagen que tenga texto claro. Luego prueba **Cámara** apuntando a la hoja impresa.
5. La primera vez, Android pedirá permiso para usar la cámara: pulsa **Permitir**.

**Comandos útiles mientras corre `flutter run`:**

| Tecla | Qué hace |
| --- | --- |
| `r` | Hot reload: aplica cambios de código sin reiniciar |
| `R` | Hot restart: reinicia la app y borra el estado |
| `q` | Detiene la app |

Si agregas un paquete nuevo, no basta con `r`: detén con `q` y vuelve a ejecutar `flutter run`.

> **Prueba de que es local:** activa el modo avión en el celular y vuelve a leer un texto. Sigue funcionando, porque el modelo está dentro de la app.

---

## Código final completo (`lib/main.dart`)

Si te atrasaste o algo no compila, reemplaza todo `lib/main.dart` por esto:

```dart
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
```

---

## Errores comunes

| Problema | Solución |
| --- | --- |
| Error de `minSdk` al compilar | Sube el valor mínimo a 21 en `build.gradle(.kts)` ([Paso 3](#paso-3-configurar-android-y-ios-si-aplica)) |
| `MissingPluginException` | Detén la app y vuelve a ejecutar `flutter run` (el hot reload no carga paquetes nuevos) |
| La app se ejecuta en Chrome o Windows | Selecciona tu celular como dispositivo ([Paso 0.3](#03-seleccionar-el-celular-en-vs-code)) |
| No reconoce nada o reconoce basura | Mejor luz, foto de frente, texto enfocado y letra grande |
| El celular no aparece en `flutter devices` | Usa un cable de datos, acepta el aviso de depuración USB y cambia el modo USB a Transferencia de archivos |
| La primera compilación tarda mucho | Es normal: Gradle descarga las dependencias de ML Kit |

---

## Retos opcionales

Si terminaste y te sobra tiempo:

- [ ] Mostrar cuántos bloques encontró (`resultado.blocks.length`)
- [ ] Listar cada bloque por separado en un `Card`
- [ ] Agregar un botón para copiar el texto con `Clipboard.setData`
- [ ] Guardar un historial de lecturas

---

## Recursos

- [google_mlkit_text_recognition en pub.dev](https://pub.dev/packages/google_mlkit_text_recognition)
- [image_picker en pub.dev](https://pub.dev/packages/image_picker)
- [Documentación de ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2)
