import 'package:flutter/material.dart';
import '../core/colors.dart';

class QRVerifier extends StatefulWidget {
  final Map<String, dynamic> qrData;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  const QRVerifier({
    super.key,
    required this.qrData,
    required this.onConfirmar,
    required this.onRechazar,
  });

  @override
  State<QRVerifier> createState() => _QRVerifierState();
}

class _QRVerifierState extends State<QRVerifier> {
  bool _animado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animado = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final esValido = widget.qrData['es_valido'] == true;
    final monto = widget.qrData['monto'] ?? '---';
    final banco = widget.qrData['banco'] ?? '---';
    final numTxn = widget.qrData['num_transaccion'] ?? '---';
    final razon = widget.qrData['razon_si_invalido'];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esValido ? Icons.check_circle : Icons.cancel,
                color: esValido ? QhipuColors.primaryGreen : QhipuColors.dangerRed,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  esValido ? 'Pago verificado' : 'QR SOSPECHOSO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: esValido ? QhipuColors.primaryGreen : QhipuColors.dangerRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _checkItem('Monto: Bs $monto', esValido, 'coincide'),
          const SizedBox(height: 8),
          _checkItem(
            'Fecha y hora: ${widget.qrData['fecha'] ?? '--'} ${widget.qrData['hora'] ?? '--'}',
            esValido,
            'válidos',
          ),
          const SizedBox(height: 8),
          _checkItem(
            'Número de transacción: $numTxn',
            esValido,
            esValido ? 'real' : 'FALSO',
            colorFalso: esValido ? null : QhipuColors.dangerRed,
          ),
          if (!esValido && razon != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: QhipuColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                razon,
                style: const TextStyle(
                  color: QhipuColors.dangerRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: esValido ? QhipuColors.textMuted : QhipuColors.dangerRed,
                      side: BorderSide(
                        color: esValido ? QhipuColors.borderSoft : QhipuColors.dangerRed,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(esValido ? 'Cerrar' : 'No registrar este pago'),
                  ),
                ),
              ),
              if (esValido) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: widget.onConfirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QhipuColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirmar pago'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String texto, bool valido, String estado, {Color? colorFalso}) {
    final show = _animado;
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: valido ? QhipuColors.mintGreen : (colorFalso ?? QhipuColors.dangerBg),
              shape: BoxShape.circle,
            ),
            child: Icon(
              valido ? Icons.check : Icons.close,
              size: 12,
              color: valido ? QhipuColors.primaryGreen : (colorFalso ?? QhipuColors.dangerRed),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                color: QhipuColors.textMain,
              ),
            ),
          ),
          Text(
            estado,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valido
                  ? QhipuColors.primaryGreen
                  : (colorFalso ?? QhipuColors.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}
