import 'package:flutter/material.dart';
import '../core/colors.dart';

class TxnItem extends StatelessWidget {
  final String tipo;
  final String nombre;
  final String horaRelativa;
  final double monto;
  final bool esFiado;
  final bool esAlerta;

  const TxnItem({
    super.key,
    required this.tipo,
    required this.nombre,
    required this.horaRelativa,
    required this.monto,
    this.esFiado = false,
    this.esAlerta = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData icono;
    Color colorIcono;
    Color colorMonto;

    if (esAlerta) {
      icono = Icons.warning_amber_rounded;
      colorIcono = QhipuColors.amberAlert;
      colorMonto = QhipuColors.amberAlert;
    } else if (esFiado) {
      icono = Icons.bookmark_border;
      colorIcono = QhipuColors.dangerRed;
      colorMonto = QhipuColors.dangerRed;
    } else {
      icono = Icons.shopping_bag_outlined;
      colorIcono = QhipuColors.primaryGreen;
      colorMonto = QhipuColors.primaryGreen;
    }

    final montoStr = monto >= 0
        ? '+Bs ${monto.toStringAsFixed(2)}'
        : '-Bs ${monto.abs().toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorIcono.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: colorIcono, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: QhipuColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  horaRelativa,
                  style: const TextStyle(
                    fontSize: 11,
                    color: QhipuColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            montoStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorMonto,
            ),
          ),
        ],
      ),
    );
  }
}
