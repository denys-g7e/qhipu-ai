import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import '../../core/firestore_service.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _filtro = 'Todo';
  String _busqueda = '';
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _ventaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();

  static const _categorias = ['Ropa', 'Accesorios', 'Calzado', 'Otros'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _costoCtrl.dispose();
    _ventaCtrl.dispose();
    _stockCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  void _mostrarAgregarProducto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QhipuColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar producto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: QhipuColors.textMain,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDec('Nombre del producto'),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriaCtrl,
                decoration: _inputDec('Categoría'),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      decoration: _inputDec('Precio costo'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Req.' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ventaCtrl,
                      decoration: _inputDec('Precio venta'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Req.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                decoration: _inputDec('Stock inicial'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _guardarProducto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QhipuColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar producto'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: QhipuColors.textMuted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QhipuColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QhipuColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QhipuColors.primaryGreen),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(firestoreProvider);
    await service.addProducto(
      nombre: _nombreCtrl.text,
      categoria: _categoriaCtrl.text,
      precioCosto: double.parse(_costoCtrl.text),
      precioVenta: double.parse(_ventaCtrl.text),
      stockActual: int.parse(_stockCtrl.text),
    );

    _nombreCtrl.clear();
    _costoCtrl.clear();
    _ventaCtrl.clear();
    _stockCtrl.clear();
    _categoriaCtrl.clear();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(_productosProvider);

    return Scaffold(
      backgroundColor: QhipuColors.surfaceMain,
      appBar: AppBar(
        backgroundColor: QhipuColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Inventario',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: QhipuColors.cardWhite,
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: QhipuColors.surfaceMain,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QhipuColors.borderSoft),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle: TextStyle(color: QhipuColors.textHint, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: QhipuColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14, color: QhipuColors.textMain),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Todo', 'Stock bajo', ..._categorias].map((f) {
                      final seleccionado = _filtro == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filtro = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? QhipuColors.primaryGreen
                                  : QhipuColors.surfaceMain,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: seleccionado
                                    ? QhipuColors.primaryGreen
                                    : QhipuColors.borderSoft,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: seleccionado
                                      ? Colors.white
                                      : QhipuColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error al cargar productos')),
              data: (productos) {
                if (productos.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes productos registrados.\nAgrega tu primer producto con el botón +',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: QhipuColors.textMuted),
                    ),
                  );
                }

                final filtrados = productos.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                  final categoria = (data['categoria'] ?? '').toString();
                  final stock = (data['stock_actual'] ?? 0).toInt();
                  final stockMin = (data['stock_minimo'] ?? 5).toInt();

                  if (_busqueda.isNotEmpty && !nombre.contains(_busqueda)) return false;
                  if (_filtro == 'Stock bajo' && stock > stockMin) return false;
                  if (_filtro != 'Todo' && _filtro != 'Stock bajo' && categoria != _filtro) return false;
                  return true;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final data = filtrados[i].data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? '';
                    final categoria = data['categoria'] ?? '';
                    final precioVenta = (data['precio_venta'] ?? 0).toDouble();
                    final stock = (data['stock_actual'] ?? 0).toInt();
                    final stockMin = (data['stock_minimo'] ?? 5).toInt();
                    final pct = stockMin > 0 ? (stock / stockMin) : 1.0;

                    String estado;
                    Color estadoColor;
                    Color barColor;
                    if (stock <= 0) {
                      estado = 'Crítico';
                      estadoColor = QhipuColors.dangerRed;
                      barColor = QhipuColors.dangerRed;
                    } else if (stock <= stockMin) {
                      estado = 'Bajo';
                      estadoColor = QhipuColors.amberAlert;
                      barColor = QhipuColors.amberAlert;
                    } else {
                      estado = 'OK';
                      estadoColor = QhipuColors.primaryGreen;
                      barColor = QhipuColors.primaryGreen;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: QhipuColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QhipuColors.borderSoft, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: QhipuColors.surfaceMain,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              categoria == 'Ropa'
                                  ? Icons.checkroom
                                  : categoria == 'Accesorios'
                                      ? Icons.watch
                                      : Icons.category_outlined,
                              color: QhipuColors.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: QhipuColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct.clamp(0.0, 1.0),
                                    backgroundColor: QhipuColors.surfaceMain,
                                    valueColor: AlwaysStoppedAnimation(barColor),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bs $precioVenta · $stock unid.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: QhipuColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estado == 'OK'
                                  ? QhipuColors.mintGreen
                                  : estado == 'Bajo'
                                      ? QhipuColors.amberBg
                                      : QhipuColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          onPressed: _mostrarAgregarProducto,
          backgroundColor: QhipuColors.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

final _productosProvider = StreamProvider((ref) {
  final service = ref.read(firestoreProvider);
  return service.getProductos();
});
