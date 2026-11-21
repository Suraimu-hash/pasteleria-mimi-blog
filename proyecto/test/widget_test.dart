import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto/main.dart';

void main() {
  testWidgets('la app abre en el inicio de sesión de Pastelería Mimi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MimiApp());

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Pastelería Mimi'), findsWidgets);
    expect(find.text('INGRESAR'), findsOneWidget);
  });
}
