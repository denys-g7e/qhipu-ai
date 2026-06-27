import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/colors.dart';
import '../../core/groq_service.dart';
import '../../core/firestore_service.dart';
import '../../widgets/qr_verifier.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _mensajes = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final GroqService _groq = GroqService();
  bool _escuchando = false;
  bool _procesando = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _mensajes.add({
      'rol': 'ia',
      'texto': '¡Hola! Soy Qhipu, tu contador inteligente. '
          'Dime qué vendiste hoy y yo lo registro por ti.',
    });
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarTexto(String texto) async {
    if (texto.trim().isEmpty) return;

    setState(() {
      _mensajes.add({'rol': 'usuario', 'texto': texto.trim()});
      _procesando = true;
    });
    _scrollAbajo();

    final respuesta = await _groq.chat(texto.trim());
    await _procesarRespuesta(respuesta);
  }

  Future<void> _procesarRespuesta(String respuesta) async {
    try {
      final jsonStart = respuesta.indexOf('{');
      final jsonEnd = respuesta.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = respuesta.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;

        if (data['accion'] == 'registrar_venta') {
          final productos = data['productos'] as List<dynamic>;
          final metodoPago = data['metodo_pago'] ?? 'efectivo';
          final cliente = data['cliente'];
          double total = 0;
          for (var p in productos) {
            total += (p['cantidad'] as num).toDouble() * (p['precio_unitario'] as num).toDouble();
          }

          final service = ref.read(firestoreProvider);
          await service.addTransaccion(
            tipo: metodoPago == 'fiado' ? 'fiado' : 'venta',
            productos: productos.map((p) => {
              'nombre': p['nombre'],
              'cantidad': p['cantidad'],
              'precio_unitario': p['precio_unitario'],
            }).toList(),
            total: total,
            metodoPago: metodoPago,
            clienteFiado: cliente,
          );

          final textoRespuesta = data['respuesta_texto'] ?? 'Venta registrada con éxito';
          setState(() {
            _mensajes.add({'rol': 'ia', 'texto': textoRespuesta});
            _procesando = false;
          });
          _scrollAbajo();
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _mensajes.add({'rol': 'ia', 'texto': respuesta});
      _procesando = false;
    });
    _scrollAbajo();
  }

  Future<void> _iniciarVoz() async {
    final disponible = await _speech.initialize();
    if (!disponible) return;

    setState(() => _escuchando = true);
    await _speech.listen(
      onResult: (result) => _textController.text = result.recognizedWords,
      localeId: 'es',
    );
  }

  void _detenerVoz() {
    _speech.stop();
    setState(() => _escuchando = false);

    if (_textController.text.trim().isNotEmpty) {
      final texto = _textController.text.trim();
      _textController.clear();
      _enviarTexto(texto);
    }
  }

  void _abrirScannerQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QhipuColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScannerQRSheet(
        onScanned: (qrText) {
          Navigator.pop(context);
          _analizarQR(qrText);
        },
      ),
    );
  }

  Future<void> _analizarQR(String qrText) async {
    setState(() {
      _mensajes.add({
        'rol': 'usuario',
        'texto': '📱 Escaneando QR...',
      });
      _procesando = true;
    });
    _scrollAbajo();

    final qrData = await _groq.analyzeQrText(qrText);

    setState(() => _procesando = false);

    if (!mounted) return;
    _mostrarQRVerifier(qrData);
  }

  void _mostrarQRVerifier(Map<String, dynamic> qrData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QhipuColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QRVerifier(
        qrData: qrData,
        onConfirmar: () {
          Navigator.pop(context);
          setState(() {
            _mensajes.add({
              'rol': 'ia',
              'texto': '✅ Pago verificado y registrado correctamente.\n'
                  'Monto: Bs ${qrData['monto'] ?? '---'}',
            });
          });
          _scrollAbajo();
        },
        onRechazar: () {
          Navigator.pop(context);
          if (qrData['es_valido'] != true) {
            setState(() {
              _mensajes.add({
                'rol': 'ia',
                'texto': '⚠️ QR sospechoso detectado. No se registró el pago.\n'
                    'Recomendación: No aceptes este comprobante.',
              });
            });
            _scrollAbajo();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QhipuColors.surfaceMain,
      appBar: AppBar(
        backgroundColor: QhipuColors.primaryGreen,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: QhipuColors.lightGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'Q',
                  style: TextStyle(color: QhipuColors.lightGreen, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qhipu AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('En línea', style: TextStyle(fontSize: 11, color: QhipuColors.lightGreen)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _mensajes.length + (_procesando ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _mensajes.length && _procesando) {
                  return _buildCargando();
                }
                final msg = _mensajes[index];
                return _buildBurbuja(msg);
              },
            ),
          ),
          if (_escuchando)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: QhipuColors.mintGreen,
              child: Row(
                children: [
                  const Icon(Icons.mic, color: QhipuColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Escuchando... ${_specialText()}',
                    style: const TextStyle(color: QhipuColors.primaryGreen),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _detenerVoz,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: QhipuColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  String _specialText() {
    final dots = (_animCtrl.value * 4).floor();
    return '.' * dots.clamp(0, 3);
  }

  Widget _buildCargando() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: QhipuColors.primaryGreen,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topLeft: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Qhipu piensa${_specialText()}',
                style: const TextStyle(color: QhipuColors.lightGreen, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBurbuja(Map<String, dynamic> msg) {
    final esUsuario = msg['rol'] == 'usuario';
    final texto = msg['texto'] as String;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: esUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!esUsuario)
              Container(
                margin: const EdgeInsets.only(bottom: 4, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: QhipuColors.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Qhipu AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: QhipuColors.primaryGreen,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: esUsuario ? const Color(0xFFe8f5ed) : QhipuColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: esUsuario ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: esUsuario ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: esUsuario
                    ? Border.all(color: const Color(0xFFbbf7d0))
                    : null,
              ),
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  color: esUsuario ? QhipuColors.textMain : Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: QhipuColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: _abrirScannerQR,
                icon: const Icon(Icons.qr_code_scanner, color: QhipuColors.primaryGreen, size: 22),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: QhipuColors.surfaceMain,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: QhipuColors.borderSoft),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe o usa el micrófono...',
                    hintStyle: TextStyle(color: QhipuColors.textHint, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14, color: QhipuColors.textMain),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _textController.clear();
                      _enviarTexto(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: _escuchando ? _detenerVoz : _iniciarVoz,
                icon: Icon(
                  _escuchando ? Icons.stop : Icons.mic,
                  color: _escuchando ? QhipuColors.dangerRed : QhipuColors.primaryGreen,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerQRSheet extends StatefulWidget {
  final Function(String) onScanned;

  const _ScannerQRSheet({required this.onScanned});

  @override
  State<_ScannerQRSheet> createState() => _ScannerQRSheetState();
}

class _ScannerQRSheetState extends State<_ScannerQRSheet> {
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: QhipuColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Escanea el QR del comprobante',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: QhipuColors.textMain),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      widget.onScanned(barcodes.first.rawValue!);
                    }
                  },
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Apunta la cámara al código QR del pago',
              style: TextStyle(color: QhipuColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}