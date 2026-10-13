Integrantes: 
Julio Andrés Diaz Maigual - Paula Vanessa León Erazo
------------------------------------------------------------------------------------------------------------------------------------------
# OCR local en Flutter con Google ML Kit

App de ejemplo en Flutter que toma una foto (o la elige de la galería), **extrae el texto** que aparece en ella usando **Google ML Kit** y además **detecta automáticamente correos, celulares y valores en pesos** dentro de ese texto. Todo ocurre dentro del celular y **sin internet**.

Este repositorio acompaña un taller práctico: puedes seguir la guía paso a paso o clonar el proyecto y ejecutarlo directamente.

**Paquete principal:** [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition)

---

## Tabla de contenido

- [Requisitos](#requisitos)
- [Teoría en 5 minutos](#teoría-en-5-minutos)
- [¿Por qué esto es inteligencia artificial?](#por-qué-esto-es-inteligencia-artificial)
- [Arquitectura: cómo se integra ML Kit en Flutter](#arquitectura-cómo-se-integra-ml-kit-en-flutter)
- [Casos de uso reales](#casos-de-uso-reales)
- [Ejecutar este repositorio](#ejecutar-este-repositorio)
- [Guía paso a paso](#guía-paso-a-paso)
  - [Paso 0: Preparar el entorno](#paso-0-preparar-el-entorno)
  - [Paso 1: Crear el proyecto](#paso-1-crear-el-proyecto)
  - [Paso 2: Instalar los paquetes](#paso-2-instalar-los-paquetes)
  - [Paso 3: Configurar Android (y iOS si aplica)](#paso-3-configurar-android-y-ios-si-aplica)
  - [Paso 4: Preparar la pantalla](#paso-4-preparar-la-pantalla)
  - [Paso 5: La función que lee el texto](#paso-5-la-función-que-lee-el-texto)
  - [Paso 6: Extraer datos útiles del texto](#paso-6-extraer-datos-útiles-del-texto)
  - [Paso 7: Construir la interfaz](#paso-7-construir-la-interfaz)
  - [Paso 8: Ejecutar y probar](#paso-8-ejecutar-y-probar)
- [Código final completo](#código-final-completo-libmaindart)
- [¿Usa base de datos?](#usa-base-de-datos)
- [Errores comunes](#errores-comunes)
- [Retos opcionales](#retos-opcionales)
- [Recursos](#recursos)

---

## Requisitos

- [ ] Flutter instalado y funcionando (`flutter doctor` sin errores en Android)
- [ ] Un **celular Android físico** y un cable USB de datos
- [ ] Un editor (VS Code o Android Studio) con el plugin de Flutter
- [ ] Una hoja con texto impreso (letra grande) para hacer pruebas. Ideal: una factura o tarjeta de presentación con correo, celular y precios

> **Importante:** ML Kit solo funciona en Android e iOS. No sirve en Chrome, Windows ni Linux, así que no ejecutes el proyecto en esas plataformas.

---

## Teoría en 5 minutos

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

## ¿Por qué esto es inteligencia artificial?

El reconocimiento de texto de ML Kit **no funciona con reglas programadas a mano** (del tipo "si hay una línea vertical y una horizontal, es una T"). Usa un modelo de **deep learning** (redes neuronales) que Google entrenó con millones de imágenes de texto en distintas fuentes, tamaños, ángulos y condiciones de luz.

Por eso puede leer letra impresa en una hoja arrugada, un letrero en la calle o la pantalla de otro celular: el modelo **aprendió** a reconocer patrones, no los memorizó.

| Enfoque tradicional | Enfoque con IA (ML Kit) |
| --- | --- |
| Reglas escritas por un programador | Patrones aprendidos de millones de ejemplos |
| Falla con fuentes o ángulos nuevos | Generaliza a casos que nunca vio |
| Hay que actualizar las reglas a mano | Se mejora reentrenando el modelo |

Además, es un ejemplo de **IA en el borde (Edge AI)**: el modelo se ejecuta en el propio dispositivo y no en un servidor en la nube.

---

## Arquitectura: cómo se integra ML Kit en Flutter

Flutter **no hace el OCR por sí mismo**. El paquete funciona como un puente hacia el SDK nativo de Google:

```
┌─────────────────────────────────────────┐
│  Tu app en Dart (main.dart)             │
│  _recognizer.processImage(input)        │
└───────────────────┬─────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Plugin google_mlkit_text_recognition   │
└───────────────────┬─────────────────────┘
                    ↓  Platform Channel (puente Flutter ↔ nativo)
┌─────────────────────────────────────────┐
│  SDK nativo de ML Kit                   │
│  Android: Kotlin/Java · iOS: Swift      │
└───────────────────┬─────────────────────┘
                    ↓  ejecuta
┌─────────────────────────────────────────┐
│  Modelo de red neuronal (dentro del APK)│
└─────────────────────────────────────────┘
        El texto reconocido regresa por el mismo camino ↑
```

1. Tu código Dart llama a `processImage()`.
2. El plugin envía la imagen al lado nativo por un **Platform Channel**, el mecanismo que Flutter usa para comunicarse con Android e iOS.
3. El SDK nativo de ML Kit ejecuta el modelo de red neuronal en el procesador del celular.
4. El resultado (`RecognizedText`) vuelve a Dart.
5. En Dart, la función `_extraerDatos` busca correos, celulares y valores en ese texto, y todo se muestra en pantalla.

---

## Casos de uso reales

### El caso de uso que implementa esta app

Leer texto es solo el primer paso; lo útil es **hacer algo con ese texto**. Después del OCR, la app usa **expresiones regulares** para encontrar automáticamente:

| Dato | Ejemplo |
| --- | --- |
| Correos electrónicos | `ventas@tienda.com` |
| Celulares colombianos (10 dígitos, empiezan por 3) | `310 555 1234` |
| Valores en pesos | `$45.900` |

Sirve, por ejemplo, para digitalizar **tarjetas de presentación**, leer el total de una **factura** o capturar los datos de contacto de un **afiche**.

> En una frase: **ML Kit convierte la imagen en texto, y con expresiones regulares convertimos ese texto en datos útiles.**

### Otros casos de uso

| Área | Caso de uso | Cómo se usaría el OCR |
| --- | --- | --- |
| Finanzas personales | Registrar gastos desde facturas | Se toma foto al recibo y se extraen el total y la fecha |
| Accesibilidad | Lectura para personas con baja visión | El texto reconocido se lee en voz alta con un paquete de texto a voz (`flutter_tts`) |
| Educación | Digitalizar apuntes | Se fotografía el tablero o una fotocopia y el texto queda editable |
| Movilidad | Control de parqueaderos | Se lee la placa del vehículo al entrar y salir |
| Registro de usuarios | Autocompletar formularios | Se lee el nombre y número de un documento para llenar los campos |
| Turismo | Traducción de letreros | Se combina el OCR con otro modelo de ML Kit para traducir |

**Ventaja clave en todos los casos:** como el procesamiento es local, funciona en zonas sin buena señal y los datos sensibles (facturas, documentos) **nunca salen del celular**.

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

**Borra el test de ejemplo:** elimina el archivo `test/widget_test.dart`. Ese archivo prueba la app del contador que Flutter crea por defecto (`MyApp`); como vamos a reemplazar todo `main.dart`, quedaría marcado en rojo.

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

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: OcrPage()));

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
  String _datos = '';     // correos, celulares y valores encontrados
  bool _cargando = false; // para mostrar un indicador de carga

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Aquí irá la UI')));
  }
}
```

- `debugShowCheckedModeBanner: false` quita la cinta roja de **DEBUG** de la esquina superior derecha.
- `TextRecognitionScript.latin` sirve para español e inglés. Existen otros alfabetos (chino, japonés, coreano, devanagari) que requieren paquetes adicionales.

---

### Paso 5: La función que lee el texto

Este es el corazón del taller. Pégala dentro de `_OcrPageState`, encima de `build`:

```dart
Future<void> _leerTexto(ImageSource origen) async {
  // 1. Tomar la foto o elegirla de la galería
  final foto = await _picker.pickImage(source: origen);
  if (foto == null) return; // el usuario canceló

  setState(() {
    _imagen = File(foto.path);
    _cargando = true;
    _datos = ''; // borra los datos de la foto anterior
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

@override
void dispose() {
  _recognizer.close(); // 5. Liberar el modelo de la memoria
  super.dispose();
}
```

Fíjate en que los números de los comentarios son los mismos 5 pasos de la teoría. `_extraerDatos` todavía no existe y quedará marcada en rojo; la creamos en el siguiente paso.

---

### Paso 6: Extraer datos útiles del texto

Pega esta función dentro de `_OcrPageState`, debajo de `_leerTexto`:

```dart
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
```

**Cómo funciona:**

- `RegExp(...)` define un **patrón**: la "forma" del dato que buscamos.
- `allMatches(texto)` encuentra **todas** las coincidencias en el texto.
- `m.group(0)` es el texto exacto que coincidió.
- `...` (spread) mete los resultados de las tres búsquedas en una sola lista.
- `join('\n')` une todo en un texto, un dato por línea. Si no encontró nada, devuelve `''`.

**Qué significa cada patrón:**

| Patrón | Busca | Detalle |
| --- | --- | --- |
| `[\w.\-]+@[\w\-]+\.[\w.]+` | Correos | usuario + `@` + dominio + `.` + extensión |
| `3\d{2}[\s-]?\d{3}[\s-]?\d{4}` | Celulares colombianos | Empieza por 3, 10 dígitos, con espacios o guiones opcionales |
| `\$\s?[\d.,]+` | Valores en pesos | Signo `$`, espacio opcional y números con puntos o comas |

Símbolos usados: `\w` letra, número o guion bajo · `\d` dígito · `\s` espacio · `+` uno o más · `?` opcional · `{n}` exactamente n veces. La `r` antes de las comillas evita que Dart interprete las barras `\`.

---

### Paso 7: Construir la interfaz

Reemplaza el método `build` por este:

```dart
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
```

- `SelectableText` permite seleccionar y copiar el texto reconocido sin programar nada extra.
- La tarjeta **Datos detectados** (`Card`) solo aparece si `_extraerDatos` encontró algo. `margin` es el espacio por fuera de la tarjeta y `padding` el espacio por dentro.

---

### Paso 8: Ejecutar y probar

1. Verifica que el dispositivo seleccionado (esquina inferior derecha de VS Code) sea tu celular Android, no Chrome ni Windows.
2. Ejecuta la app con **F5** (o **Run → Start Debugging**), o desde la terminal:

   ```bash
   flutter run
   ```

3. La primera compilación puede tardar entre 3 y 10 minutos, porque Gradle descarga las dependencias de ML Kit. Necesitas internet solo esta vez.
4. Cuando abra la app, prueba **Galería** primero con una imagen que tenga texto claro. Luego prueba **Cámara** apuntando a la hoja impresa.
5. La primera vez, Android pedirá permiso para usar la cámara: pulsa **Permitir**.
6. Prueba con una factura o tarjeta que tenga correo, celular o precios: debe aparecer la tarjeta **Datos detectados**.

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

Si te atrasaste o algo no compila, reemplaza todo `lib/main.dart` por esto. Los comentarios explican cada parte y los números de **PASO 1 a PASO 5** coinciden con el patrón de ML Kit de la teoría:

```dart
// =============================================================
// OCR local en Flutter con Google ML Kit
// -------------------------------------------------------------
// App de una sola pantalla que toma una foto (cámara o galería),
// extrae el texto usando un modelo de IA que se ejecuta dentro
// del celular (sin internet) y detecta correos, celulares y
// valores dentro de ese texto.
// =============================================================

// File: representa un archivo guardado en el celular (la foto).
import 'dart:io';

// Widgets visuales de Flutter (Scaffold, AppBar, botones, etc.).
import 'package:flutter/material.dart';

// Paquete para abrir la cámara o la galería y obtener una imagen.
import 'package:image_picker/image_picker.dart';

// Paquete de Google ML Kit para reconocimiento de texto (OCR).
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Punto de entrada de la app: se ejecuta primero al abrirla.
// MaterialApp aplica el estilo Material Design, la cinta de DEBUG
// se oculta y OcrPage es la pantalla inicial.
void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: OcrPage()));

// -------------------------------------------------------------
// Pantalla principal.
// Es StatefulWidget porque su contenido cambia: primero vacía,
// luego muestra la foto, el indicador de carga, el texto y los
// datos detectados.
// -------------------------------------------------------------
class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  // Crea el objeto que guarda el estado (variables y lógica).
  @override
  State<OcrPage> createState() => _OcrPageState();
}

// -------------------------------------------------------------
// Estado de la pantalla.
// El guion bajo (_) hace que la clase sea privada a este archivo.
// -------------------------------------------------------------
class _OcrPageState extends State<OcrPage> {
  // ---------- Herramientas (se crean una sola vez) ----------

  // Abre la cámara o la galería.
  final _picker = ImagePicker();

  // Reconocedor de texto de ML Kit. Al crearlo se carga el modelo
  // de red neuronal en memoria. "latin" sirve para español e inglés.
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // ---------- Estado (datos que cambian en pantalla) ----------

  // Foto elegida. El "?" indica que puede ser null (aún no hay foto).
  File? _imagen;

  // Texto reconocido por ML Kit. Empieza vacío.
  String _texto = '';

  // Correos, celulares y valores encontrados en el texto.
  String _datos = '';

  // true mientras ML Kit procesa la imagen (muestra el círculo de carga).
  bool _cargando = false;

  // -------------------------------------------------------------
  // Lee el texto de una imagen.
  // [origen] puede ser ImageSource.camera o ImageSource.gallery,
  // así una sola función sirve para los dos botones.
  // Es async porque abrir la cámara y procesar la imagen tardan.
  // -------------------------------------------------------------
  Future<void> _leerTexto(ImageSource origen) async {
    // PASO 1: Conseguir la imagen.
    // "await" espera a que el usuario tome o elija la foto.
    final foto = await _picker.pickImage(source: origen);

    // Si el usuario canceló, no hay foto: salimos de la función.
    if (foto == null) return;

    // Mostrar la foto, activar el indicador de carga y borrar
    // los datos de la foto anterior.
    // setState le indica a Flutter que vuelva a dibujar la pantalla.
    setState(() {
      _imagen = File(foto.path);
      _cargando = true;
      _datos = '';
    });

    // PASO 2: Convertir la imagen al formato que entiende ML Kit.
    final input = InputImage.fromFilePath(foto.path);

    // PASO 3: Procesar la imagen con el modelo de IA.
    // Todo ocurre dentro del celular, sin internet.
    final resultado = await _recognizer.processImage(input);

    // PASO 4: Mostrar el texto, extraer los datos útiles y quitar
    // el indicador de carga. Si no hay texto, mostramos un mensaje.
    setState(() {
      _texto = resultado.text.isEmpty ? 'No se encontró texto' : resultado.text;
      _datos = _extraerDatos(resultado.text);
      _cargando = false;
    });
  }

  // -------------------------------------------------------------
  // Caso de uso: busca correos, celulares y valores en el texto
  // usando expresiones regulares (patrones de texto).
  // Devuelve un dato por línea, o '' si no encontró nada.
  // -------------------------------------------------------------
  String _extraerDatos(String texto) {
    // Correo: usuario + @ + dominio + . + extensión.
    final correos = RegExp(r'[\w.\-]+@[\w\-]+\.[\w.]+').allMatches(texto);

    // Celular colombiano: empieza por 3, 10 dígitos,
    // con espacios o guiones opcionales (310 555 1234).
    final celulares = RegExp(r'3\d{2}[\s-]?\d{3}[\s-]?\d{4}').allMatches(texto);

    // Valor en pesos: signo $, espacio opcional y números ($45.900).
    final valores = RegExp(r'\$\s?[\d.,]+').allMatches(texto);

    // "..." mete todas las coincidencias en una sola lista.
    // m.group(0) es el texto exacto que coincidió con el patrón.
    final lineas = <String>[
      ...correos.map((m) => 'Correo: ${m.group(0)}'),
      ...celulares.map((m) => 'Celular: ${m.group(0)}'),
      ...valores.map((m) => 'Valor: ${m.group(0)}'),
    ];

    // Une todo en un texto, con un salto de línea entre cada dato.
    return lineas.join('\n');
  }

  // -------------------------------------------------------------
  // Se ejecuta automáticamente al cerrar la pantalla.
  // -------------------------------------------------------------
  @override
  void dispose() {
    // PASO 5: Liberar el modelo de la memoria para evitar fugas.
    _recognizer.close();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Dibuja la interfaz. Flutter lo llama al inicio y cada vez
  // que se usa setState.
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior con el título.
      appBar: AppBar(title: const Text('OCR con ML Kit')),

      // ListView permite hacer scroll si el texto es largo.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Botones Cámara y Galería ----------
          Row(
            children: [
              // Expanded hace que cada botón ocupe la mitad del ancho.
              Expanded(
                child: ElevatedButton.icon(
                  // "() =>" ejecuta la función solo al tocar el botón.
                  onPressed: () => _leerTexto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
              ),

              // Espacio horizontal entre los botones.
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

          // ---------- Imagen seleccionada ----------
          // Solo se muestra si ya hay una foto.
          // El "!" asegura a Dart que _imagen no es null (ya lo comprobó el if).
          if (_imagen != null) Image.file(_imagen!, height: 250),

          const SizedBox(height: 16),

          // ---------- Resultado ----------
          // Mientras procesa: círculo de carga.
          // Al terminar: texto reconocido. SelectableText permite
          // seleccionarlo y copiarlo manteniendo presionado.
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else
            SelectableText(_texto),

          // ---------- Datos detectados ----------
          // Solo aparece si se encontraron correos, celulares o valores.
          // margin = espacio por fuera; padding = espacio por dentro.
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
```

---

## ¿Usa base de datos?

**No.** Nada se guarda de forma permanente:

- **El modelo de ML Kit** es una red neuronal ya entrenada por Google que viene empaquetada dentro de la app. Se carga en la RAM al crear el `TextRecognizer` y se libera con `close()` en `dispose()`.
- **La foto** queda en la caché de la app (`foto.path`), que Android puede borrar cuando necesite espacio.
- **El texto y los datos detectados** solo viven en variables (`_texto`, `_datos`) mientras la pantalla está abierta. Al cerrar la app, se pierden.

Si quisieras guardar un historial, podrías usar opciones locales como `shared_preferences`, `sqflite` o `hive` (ver [Retos opcionales](#retos-opcionales)).

---

## Errores comunes

| Problema | Solución |
| --- | --- |
| Error de `minSdk` al compilar | Sube el valor mínimo a 21 en `build.gradle(.kts)` ([Paso 3](#paso-3-configurar-android-y-ios-si-aplica)) |
| `MissingPluginException` | Detén la app y vuelve a ejecutar `flutter run` (el hot reload no carga paquetes nuevos) |
| `MyApp` marcado en rojo en `test/widget_test.dart` | Borra ese archivo: es el test de la app del contador que trae Flutter por defecto |
| La app se ejecuta en Chrome o Windows | Selecciona tu celular como dispositivo ([Paso 0.3](#03-seleccionar-el-celular-en-vs-code)) |
| No reconoce nada o reconoce basura | Mejor luz, foto de frente, texto enfocado y letra grande |
| No aparece la tarjeta de datos | El texto no tenía correos, celulares ni valores, o el OCR confundió caracteres (por ejemplo `O` por `0`) |
| El celular no aparece en `flutter devices` | Usa un cable de datos, acepta el aviso de depuración USB y cambia el modo USB a Transferencia de archivos |
| La primera compilación tarda mucho | Es normal: Gradle descarga las dependencias de ML Kit |

**Limitaciones de los patrones:** un correo al final de una frase puede incluir el punto final; solo se detectan celulares colombianos (no fijos ni números extranjeros); y los valores sin signo `$` (por ejemplo "45.900 COP") no se detectan.

---

## Retos opcionales

Si terminaste y te sobra tiempo:

- [ ] Mostrar cuántos bloques encontró (`resultado.blocks.length`)
- [ ] Listar cada bloque por separado en un `Card`
- [ ] Agregar un botón para copiar los datos detectados con `Clipboard.setData`
- [ ] Detectar otro tipo de dato, por ejemplo fechas (`\d{2}/\d{2}/\d{4}`)
- [ ] Guardar un historial de lecturas con `shared_preferences` o `sqflite`

---

## Recursos

- [google_mlkit_text_recognition en pub.dev](https://pub.dev/packages/google_mlkit_text_recognition)
- [image_picker en pub.dev](https://pub.dev/packages/image_picker)
- [Documentación de ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2)
- [Expresiones regulares en Dart (`RegExp`)](https://api.dart.dev/stable/dart-core/RegExp-class.html)
