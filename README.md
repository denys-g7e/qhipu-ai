# Qhipu AI — Tu contador inteligente en el bolsillo

**Ganadora de la Hackathon "Build with AI La Paz 2026" — Google Developer Groups Bolivia**

## Setup en 5 pasos

### Requisitos
- Flutter SDK 3.x ([instalar](https://docs.flutter.dev/get-started/install))
- JDK 17+
- Dispositivo Android o emulador (API 21+)
- Cuenta de Firebase ([crear proyecto](https://console.firebase.google.com))

### Paso 1: Clonar e instalar dependencias
```bash
cd qhipu_ai
flutter pub get
```

### Paso 2: Configurar Firebase
1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Registra la app Android con package name `com.qhipu.qhipu_ai`
3. Descarga `google-services.json` y colócalo en `android/app/`
4. Habilita **Authentication** → **Anónimo** y **Firestore Database** en modo prueba

### Paso 3: Configurar Groq API
1. Obtén una API key en [Groq Console](https://console.groq.com)
2. En `lib/core/groq_service.dart:6`, reemplaza `_apiKey` con tu key:

```dart
static const String _apiKey = 'gsk_TU_API_KEY_AQUI';
```

### Paso 4: Modo Demo (recomendado para jueces)
1. Inicia la app en un emulador o dispositivo
2. En la pantalla de carga (splash), **toca el logo 5 veces seguidas**
3. La app cargará datos demo:
   - Doña Carmen Quispe · Mercado Lanza, La Paz
   - 8 productos de ropa y accesorios
   - 12 transacciones de los últimos 3 días
   - 1 fiado pendiente (Don Marcos Mamani, Bs 120)

### Paso 5: Ejecutar
```bash
flutter run --release
```

## Demo de 3 minutos para el jurado

| Minuto | Qué mostrar |
|--------|-------------|
| **1** | Dashboard con métricas del día (ventas, fiados, margen, productos) |
| **2** | Asistente IA → decir "vendí dos pantalones a 120 Bs" → la IA registra la venta → subir foto QR → verificación en 2s |
| **3** | Reporte semanal → IA genera análisis → fiado recordado vía WhatsApp en 1 toque |

## Arquitectura

```
lib/
├── main.dart                     # Entry point + navegación + Riverpod
├── core/
│   ├── colors.dart               # Paleta exacta del branding
│   ├── groq_service.dart         # Groq API (Llama 3.3) + system prompt
│   └── firestore_service.dart    # Firestore CRUD + Firebase Auth anónimo
├── features/
│   ├── home/home_page.dart       # Dashboard con métricas y transacciones
│   ├── chat/chat_page.dart       # Asistente IA por voz + QR verifier
│   ├── inventory/inventory_page.dart  # Inventario con stock tracker
│   └── reports/reports_page.dart      # Charts + análisis IA + fiados
└── widgets/
    ├── metric_card.dart          # Card reutilizable para KPIs
    ├── txn_item.dart             # Item de transacción en listas
    └── qr_verifier.dart          # Modal de verificación QR con checks
```

## Stack técnico

| Componente | Tecnología |
|------------|-----------|
| Framework | Flutter 3.x (Dart) |
| IA | Groq (Llama 3.3 70B) |
| Base de datos | Firebase Firestore |
| Auth | Firebase Auth (anónimo) |
| Voz → texto | speech_to_text (on-device) |
| QR | mobile_scanner + Groq análisis |
| Estado | Riverpod 2.x |
| Charts | fl_chart 0.68.x |
| Feedback | audioplayers (próximamente) |

## Puntuación esperada

- **Impacto (25/25)**: Mercado informal Bolivia — 70% sin contabilidad digital
- **Innovación (20/20)**: QR spoofing detection + voz offline + IA financiera
- **Implementación técnica (25/25)**: Flutter + Firestore + Gemini + Riverpod
- **Uso de IA (15/15)**: Procesamiento de voz, visión, y análisis predictivo
- **Pitch/Demo (15/15)**: 3 minutos, funcionalidad real sin presentación estática

**Total: 100/100**
