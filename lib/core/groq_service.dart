import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'gsk_DEMO_KEY_REEMPLAZAR');
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String systemPrompt = """
Eres Qhipu, asistente financiero de comerciantes bolivianos.
Hablas español boliviano coloquial. Entiende expresiones como:
"lúcas" = bolivianos, "fiado" = venta a crédito, "gremial" =
comerciante de mercado, "polera" = camiseta, "chompa" = suéter.
Cuando detectes una venta, responde SIEMPRE con JSON estructurado:
{
  "accion": "registrar_venta",
  "productos": [{"nombre":"...","cantidad":N,"precio_unitario":N}],
  "metodo_pago": "qr|efectivo|fiado",
  "cliente": "nombre si es fiado, null si no",
  "respuesta_texto": "Mensaje amigable confirmando la venta en Bs"
}
Si no es una venta, responde en texto normal ayudando al comerciante.
Siempre confirma montos en bolivianos (Bs).
""";

  static const String qrAnalysisPrompt = """
Eres un verificador de pagos QR bolivianos. El usuario te dará el texto
extraído de un código QR de pago. Analiza si es un comprobante
válido. Responde SOLO en JSON:
{
  "monto": numero o null,
  "banco": "nombre del banco o null",
  "num_transaccion": "número o null",
  "es_valido": true/false,
  "razon_si_invalido": "string o null"
}
""";

  final Map<String, String> _headers = {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  Future<String> _callGroq({
    required String systemContent,
    required String userContent,
    double temperature = 0.2,
    int maxTokens = 500,
    String model = 'llama-3.3-70b-versatile',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemContent},
            {'role': 'user', 'content': userContent},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      }
      return 'Disculpa, no entendí bien. ¿Podrías repetirlo?';
    } catch (e) {
      return 'Ups, hubo un problema con la conexión. Intenta de nuevo.';
    }
  }

  Future<String> chat(String message) async {
    return _callGroq(
      systemContent: systemPrompt,
      userContent: message,
    );
  }

  Future<Map<String, dynamic>> analyzeQrText(String qrText) async {
    try {
      final result = await _callGroq(
        systemContent: qrAnalysisPrompt,
        userContent: 'Texto del QR: $qrText',
        temperature: 0.1,
        maxTokens: 300,
      );
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        return jsonDecode(result.substring(jsonStart, jsonEnd + 1));
      }
      return {'es_valido': false, 'razon_si_invalido': 'No se pudo analizar el QR'};
    } catch (e) {
      return {'es_valido': false, 'razon_si_invalido': 'Error al procesar QR'};
    }
  }

  Future<String> generateReport(String resumen) async {
    return _callGroq(
      systemContent: 'Eres un asesor financiero de pequeños negocios bolivianos.',
      userContent:
          'Basado en estos datos de mi negocio, dame 3 recomendaciones prácticas y cortas para mejorar mis ventas:\n$resumen',
      temperature: 0.3,
      maxTokens: 400,
      model: 'llama-3.1-8b-instant',
    );
  }
}
