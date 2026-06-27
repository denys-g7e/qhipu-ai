import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/firestore_service.dart';
import '../../core/groq_service.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _periodo = 'Hoy';
  bool _analizando = false;
  String? _analisisIA;

  static const _periodos = ['Hoy', 'Esta semana', 'Este mes'];

  Future<void> _generarAnalisis() async {
    setState(() {
      _analizando = true;
      _analisisIA = null;
    });

    final service = ref.read(firestoreProvider);
    final groq = GroqService();
    final snapshot = await service.getTransacciones(limit: 50).first;
    final totalVentas = snapshot.docs
        .where((d) => (d.data() as Map)['tipo'] == 'venta')
        .fold<double>(0, (sum, d) => sum + ((d.data() as Map)['total'] ?? 0).toDouble());
    final totalFiados = snapshot.docs
        .where((d) => (d.data() as Map)['tipo'] == 'fiado')
        .fold<double>(0, (sum, d) => sum + ((d.data() as Map)['total'] ?? 0).toDouble());

    final resumen = 'Ventas: Bs $totalVentas, Fiados: Bs $totalFiados, '
        'Total transacciones: ${snapshot.docs.length}, Periodo: $_periodo';

    final resultado = await groq.generateReport(resumen);
    setState(() {
      _analisisIA = resultado;
      _analizando = false;
    });
  }

  Future<void> _recordarFiado(String cliente, double monto) async {
    final msg = 'Hola $cliente, soy de Qhipu AI. Te recuerdo que tienes un fiado pendiente de Bs ${monto.toStringAsFixed(2)}. ¡Gracias!';
    final encoded = Uri.encodeComponent(msg);
    final url = 'https://wa.me/59170000000?text=$encoded';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fiadosAsync = ref.watch(_fiadosProvider);

    return Scaffold(
      backgroundColor: QhipuColors.surfaceMain,
      appBar: AppBar(
        backgroundColor: QhipuColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Reportes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: _periodos.map((p) {
              final selected = _periodo == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _periodo = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? QhipuColors.primaryGreen : QhipuColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? QhipuColors.primaryGreen : QhipuColors.borderSoft,
                      ),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : QhipuColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QhipuColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ventas diarias',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: QhipuColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: QhipuColors.borderSoft,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              'Bs ${value.toInt()}',
                              style: const TextStyle(fontSize: 9, color: QhipuColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                              return Text(
                                dias[value.toInt() % 7],
                                style: const TextStyle(fontSize: 9, color: QhipuColors.textMuted),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(7, (i) => FlSpot(i.toDouble(), (i * 35 + 20).toDouble())),
                          color: QhipuColors.primaryGreen,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: QhipuColors.primaryGreen.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QhipuColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos más vendidos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: QhipuColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: QhipuColors.borderSoft,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 9, color: QhipuColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              const nombres = ['Poleras', 'Chompas', 'Pantalones', 'Mochilas', 'Lentes'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  nombres[value.toInt() % 5],
                                  style: const TextStyle(fontSize: 8, color: QhipuColors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(5, (i) {
                        final valores = [5.0, 3.0, 4.0, 2.0, 1.0];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: valores[i],
                              color: QhipuColors.primaryGreen,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QhipuColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Análisis IA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: QhipuColors.textMain,
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _analizando ? null : _generarAnalisis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QhipuColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _analizando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Analizar', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                if (_analisisIA != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: QhipuColors.mintGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _analisisIA!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: QhipuColors.textMain,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QhipuColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bookmark, color: QhipuColors.dangerRed, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Fiados pendientes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: QhipuColors.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                fiadosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error al cargar'),
                  data: (fiados) {
                    if (fiados.docs.isEmpty) {
                      return const Text(
                        'No tienes fiados pendientes.',
                        style: TextStyle(color: QhipuColors.textMuted, fontSize: 13),
                      );
                    }
                    return Column(
                      children: fiados.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final cliente = data['cliente_fiado'] ?? 'Cliente';
                        final total = (data['total'] ?? 0).toDouble();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: QhipuColors.dangerBg.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: QhipuColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'Bs ${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: QhipuColors.dangerRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () => _recordarFiado(cliente.toString(), total),
                                  icon: const Icon(Icons.chat_outlined, size: 16),
                                  label: const Text('Recordar', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: QhipuColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

final _fiadosProvider = StreamProvider((ref) {
  final service = ref.read(firestoreProvider);
  return service.getTransacciones(limit: 20);
});
