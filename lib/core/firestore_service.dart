import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  String get _uid => _auth.currentUser!.uid;

  Future<void> saveUserData({
    required String nombre,
    required String ciudad,
    String negocio = 'Mi negocio',
  }) async {
    await _db.collection('usuarios').doc(_uid).set({
      'nombre': nombre,
      'negocio': negocio,
      'ciudad': ciudad,
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final doc = await _db.collection('usuarios').doc(_uid).get();
    return doc.data();
  }

  Future<void> addProducto({
    required String nombre,
    required String categoria,
    required double precioCosto,
    required double precioVenta,
    required int stockActual,
    int stockMinimo = 5,
  }) async {
    await _db.collection('usuarios').doc(_uid).collection('productos').add({
      'nombre': nombre,
      'categoria': categoria,
      'precio_costo': precioCosto,
      'precio_venta': precioVenta,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getProductos() {
    return _db
        .collection('usuarios')
        .doc(_uid)
        .collection('productos')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateStock(String productoId, int cantidad) async {
    await _db
        .collection('usuarios')
        .doc(_uid)
        .collection('productos')
        .doc(productoId)
        .update({
      'stock_actual': FieldValue.increment(-cantidad),
    });
  }

  Future<void> addTransaccion({
    required String tipo,
    required List<Map<String, dynamic>> productos,
    required double total,
    required String metodoPago,
    bool qrVerificado = false,
    String? clienteFiado,
    bool iaProcesado = true,
  }) async {
    await _db.collection('usuarios').doc(_uid).collection('transacciones').add({
      'tipo': tipo,
      'productos': productos,
      'total': total,
      'metodo_pago': metodoPago,
      'qr_verificado': qrVerificado,
      'cliente_fiado': clienteFiado,
      'fecha': FieldValue.serverTimestamp(),
      'ia_procesado': iaProcesado,
    });
  }

  Stream<QuerySnapshot> getTransacciones({int? limit}) {
    Query query = _db
        .collection('usuarios')
        .doc(_uid)
        .collection('transacciones')
        .orderBy('fecha', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }

  Future<double> getVentasHoy() async {
    final inicioHoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final snapshot = await _db
        .collection('usuarios')
        .doc(_uid)
        .collection('transacciones')
        .where('fecha', isGreaterThanOrEqualTo: inicioHoy)
        .where('tipo', isEqualTo: 'venta')
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['total'] ?? 0).toDouble();
    }
    return total;
  }

  Future<double> getTotalFiados() async {
    final snapshot = await _db
        .collection('usuarios')
        .doc(_uid)
        .collection('transacciones')
        .where('tipo', isEqualTo: 'fiado')
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['total'] ?? 0).toDouble();
    }
    return total;
  }

  Future<Map<String, double>> getMetricas() async {
    final ventasHoy = await getVentasHoy();
    final fiados = await getTotalFiados();

    final productosSnap = await _db
        .collection('usuarios')
        .doc(_uid)
        .collection('productos')
        .get();
    int totalProductos = productosSnap.docs.length;
    int stockBajo = 0;
    double costoTotal = 0;
    double ventaTotal = 0;
    for (var doc in productosSnap.docs) {
      final data = doc.data();
      costoTotal += (data['precio_costo'] ?? 0).toDouble() * (data['stock_actual'] ?? 0).toDouble();
      ventaTotal += (data['precio_venta'] ?? 0).toDouble() * (data['stock_actual'] ?? 0).toDouble();
      if ((data['stock_actual'] ?? 0) <= (data['stock_minimo'] ?? 5)) {
        stockBajo++;
      }
    }
    double margen = ventaTotal > 0 ? ((ventaTotal - costoTotal) / ventaTotal) * 100 : 0;

    return {
      'ventas_hoy': ventasHoy,
      'fiados': fiados,
      'margen': margen,
      'total_productos': totalProductos.toDouble(),
      'stock_bajo': stockBajo.toDouble(),
    };
  }
}
