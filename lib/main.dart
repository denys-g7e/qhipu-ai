import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/colors.dart';
import 'core/firestore_service.dart';
import 'features/home/home_page.dart';
import 'features/chat/chat_page.dart';
import 'features/inventory/inventory_page.dart';
import 'features/reports/reports_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: QhipuApp()));
}

class QhipuApp extends StatelessWidget {
  const QhipuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qhipu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: QhipuColors.surfaceMain,
        colorScheme: ColorScheme.fromSeed(
          seedColor: QhipuColors.primaryGreen,
          primary: QhipuColors.primaryGreen,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final service = ref.read(firestoreProvider);
      await service.signInAnonymously();
    } catch (_) {}

    if (!mounted) return;

    final service = ref.read(firestoreProvider);
    final userData = await service.getUserData();

    if (!mounted) return;

    if (userData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            nombre: userData['nombre'] ?? 'Comerciante',
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            nombre: 'Doña Carmen Quispe · Mercado Lanza, La Paz',
            demoMode: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QhipuColors.primaryGreen,
      body: Center(
        child: GestureDetector(
          onTap: _onLogoTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: QhipuColors.lightGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: QhipuColors.lightGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Qhipu AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu contador inteligente en el bolsillo',
                style: TextStyle(
                  fontSize: 14,
                  color: QhipuColors.lightGreen.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: QhipuColors.lightGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nombreCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(firestoreProvider);
    await service.saveUserData(
      nombre: _nombreCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainShell(nombre: _nombreCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QhipuColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: QhipuColors.lightGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: QhipuColors.lightGreen,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido a Qhipu AI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dinos cómo te llamas y dónde vendes',
                  style: TextStyle(
                    fontSize: 14,
                    color: QhipuColors.lightGreen.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tu nombre',
                    hintStyle: const TextStyle(color: QhipuColors.textHint),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16, color: QhipuColors.textMain),
                  validator: (v) => v?.isEmpty == true ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ciudadCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ciudad (ej. La Paz)',
                    hintStyle: const TextStyle(color: QhipuColors.textHint),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16, color: QhipuColors.textMain),
                  validator: (v) => v?.isEmpty == true ? 'Ingresa tu ciudad' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QhipuColors.lightGreen,
                      foregroundColor: QhipuColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Comenzar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  final String nombre;
  final bool demoMode;

  const MainShell({
    super.key,
    required this.nombre,
    this.demoMode = false,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.demoMode) {
      _cargarDemoData();
    }
  }

  Future<void> _cargarDemoData() async {
    final service = ref.read(firestoreProvider);
    try {
      await service.addProducto(
        nombre: 'Polera cuello V',
        categoria: 'Ropa',
        precioCosto: 35,
        precioVenta: 60,
        stockActual: 12,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Pantalón jeans',
        categoria: 'Ropa',
        precioCosto: 55,
        precioVenta: 100,
        stockActual: 8,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Chompa de lana',
        categoria: 'Ropa',
        precioCosto: 70,
        precioVenta: 130,
        stockActual: 3,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Lentes de sol',
        categoria: 'Accesorios',
        precioCosto: 20,
        precioVenta: 45,
        stockActual: 15,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Mochila escolar',
        categoria: 'Accesorios',
        precioCosto: 40,
        precioVenta: 80,
        stockActual: 6,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Polera estampada',
        categoria: 'Ropa',
        precioCosto: 30,
        precioVenta: 55,
        stockActual: 2,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Chompa deportiva',
        categoria: 'Ropa',
        precioCosto: 65,
        precioVenta: 120,
        stockActual: 4,
        stockMinimo: 5,
      );
      await service.addProducto(
        nombre: 'Gorra visera',
        categoria: 'Accesorios',
        precioCosto: 15,
        precioVenta: 30,
        stockActual: 20,
        stockMinimo: 5,
      );

      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Polera cuello V', 'cantidad': 2, 'precio_unitario': 60}],
        total: 120,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Pantalón jeans', 'cantidad': 1, 'precio_unitario': 100}],
        total: 100,
        metodoPago: 'efectivo',
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Lentes de sol', 'cantidad': 3, 'precio_unitario': 45}],
        total: 135,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Polera estampada', 'cantidad': 1, 'precio_unitario': 55}],
        total: 55,
        metodoPago: 'efectivo',
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Chompa de lana', 'cantidad': 2, 'precio_unitario': 130}],
        total: 260,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Mochila escolar', 'cantidad': 1, 'precio_unitario': 80}],
        total: 80,
        metodoPago: 'efectivo',
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Polera cuello V', 'cantidad': 1, 'precio_unitario': 60}],
        total: 60,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Gorra visera', 'cantidad': 2, 'precio_unitario': 30}],
        total: 60,
        metodoPago: 'efectivo',
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Chompa deportiva', 'cantidad': 1, 'precio_unitario': 120}],
        total: 120,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Pantalón jeans', 'cantidad': 2, 'precio_unitario': 100}],
        total: 200,
        metodoPago: 'efectivo',
      );
      await service.addTransaccion(
        tipo: 'venta',
        productos: [{'nombre': 'Lentes de sol', 'cantidad': 1, 'precio_unitario': 45}],
        total: 45,
        metodoPago: 'qr',
        qrVerificado: true,
      );
      await service.addTransaccion(
        tipo: 'fiado',
        productos: [{'nombre': 'Chompa de lana', 'cantidad': 1, 'precio_unitario': 120}],
        total: 120,
        metodoPago: 'fiado',
        clienteFiado: 'Don Marcos Mamani',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onNavigateToChat: () => setState(() => _currentIndex = 1),
        nombreUsuario: widget.nombre,
      ),
      const ChatPage(),
      const InventoryPage(),
      const ReportsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: QhipuColors.borderSoft, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: QhipuColors.cardWhite,
          selectedItemColor: QhipuColors.primaryGreen,
          unselectedItemColor: QhipuColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'Asistente',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reportes',
            ),
          ],
        ),
      ),
    );
  }
}
