import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodmaps/config/theme_provider.dart';

void main() {
  testWidgets('RegistroScreen muestra formulario y botón', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 800,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: RegistroScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(); // Esperar a que se completen animaciones y layouts
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
