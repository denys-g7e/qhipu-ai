import 'package:flutter/material.dart';
import '../core/colors.dart';

class MetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;
  final Color colorFondo;
  final String? badge;
  final Color? badgeColor;

  const MetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.colorIcono = QhipuColors.primaryGreen,
    this.colorFondo = QhipuColors.cardWhite,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: colorIcono, size: 22),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? QhipuColors.amberBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor == QhipuColors.dangerRed
                          ? QhipuColors.dangerRed
                          : QhipuColors.amberAlert,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: QhipuColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: QhipuColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
