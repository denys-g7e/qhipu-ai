import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import '../../core/firestore_service.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/txn_item.dart';

final metricasProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.read(firestoreProvider);
  return service.getMetricas();
});

class HomePage extends ConsumerWidget {
  final VoidCallback onNavigateToChat;
  final String nombreUsuario;

  const HomePage({
    super.key,
    required this.onNavigateToChat,
    this.nombreUsuario = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricasAsync = ref.watch(metricasProvider);

    return Scaffold(
      backgroundColor: QhipuColors.surfaceMain,
      appBar: AppBar(
        backgroundColor: QhipuColors.primaryGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qhipu AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              nombreUsuario.isNotEmpty ? nombreUsuario : 'Cargando...',
              style: const TextStyle(fontSize: 12, color: QhipuColors.lightGreen),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: QhipuColors.amberAlert,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: metricasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar métricas')),
        data: (metricas) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(metricasProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    MetricCard(
                      titulo: 'Ventas hoy',
                      valor: 'Bs ${metricas['ventas_hoy']!.toStringAsFixed(2)}',
                      icono: Icons.trending_up,
                      colorIcono: QhipuColors.primaryGreen,
                      badge: '+12%',
                    ),
                    MetricCard(
                      titulo: 'Fiados',
                      valor: 'Bs ${metricas['fiados']!.toStringAsFixed(2)}',
                      icono: Icons.bookmark_outline,
                      colorIcono: QhipuColors.dangerRed,
                      badge: 'Pendiente',
                      badgeColor: QhipuColors.dangerRed,
                    ),
                    MetricCard(
                      titulo: 'Margen neto',
                      valor: '${metricas['margen']!.toStringAsFixed(0)}%',
                      icono: Icons.pie_chart_outline,
                      colorIcono: QhipuColors.amberAlert,
                    ),
                    MetricCard(
                      titulo: 'Productos',
                      valor: '${metricas['total_productos']!.toInt()}',
                      icono: Icons.inventory_2_outlined,
                      colorIcono: QhipuColors.secondaryGreen,
                      badge: '${metricas['stock_bajo']!.toInt()} bajo',
                      badgeColor: metricas['stock_bajo']! > 0
                          ? QhipuColors.dangerBg
                          : QhipuColors.mintGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Últimas transacciones',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: QhipuColors.textMain),
                    ),
                    Text(
                      'Ver todo',
                      style: TextStyle(fontSize: 12, color: QhipuColors.primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ultimasTransacciones(ref),
              ],
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: onNavigateToChat,
          backgroundColor: QhipuColors.primaryGreen,
          child: const Icon(Icons.mic, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _ultimasTransacciones(WidgetRef ref) {
    final txnsAsync = ref.watch(_ultimasTxnsProvider);
    return txnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (txns) {
        if (txns.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text(
              'Aún no hay transacciones.\n¡Empieza vendiendo!',
              textAlign: TextAlign.center,
              style: TextStyle(color: QhipuColors.textMuted),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: QhipuColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
          ),
          child: Column(
            children: txns.map((txn) {
              final data = txn.data() as Map<String, dynamic>;
              final tipo = data['tipo'] ?? 'venta';
              final productos = data['productos'] as List<dynamic>? ?? [];
              final nombre = productos.isNotEmpty
                  ? productos.first['nombre'] ?? 'Producto'
                  : 'Transacción';
              final total = (data['total'] ?? 0).toDouble();
              final esFiado = tipo == 'fiado';
              final esAlerta = data['qr_verificado'] == false;

              return TxnItem(
                tipo: tipo,
                nombre: nombre.toString(),
                horaRelativa: 'Hace ${DateTime.now().minute % 60} min',
                monto: esFiado ? -total : total,
                esFiado: esFiado,
                esAlerta: esAlerta,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

final _ultimasTxnsProvider = FutureProvider((ref) async {
  final service = ref.read(firestoreProvider);
  final snapshot = await service.getTransacciones(limit: 10).first;
  return snapshot.docs;
});
