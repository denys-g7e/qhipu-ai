import 'package:flutter_test/flutter_test.dart';
import 'package:qhipu_ai/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QhipuApp()));
    expect(find.text('Qhipu AI'), findsOneWidget);
    expect(find.text('Tu contador inteligente en el bolsillo'), findsOneWidget);
  });
}
