import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('LoginScreen muestra formulario y botón', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

