import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/publica/new_restaurante.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('NewRestauranteScreen se construye correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NewRestauranteScreen()));
    expect(find.byType(NewRestauranteScreen), findsOneWidget);
    // Puedes agregar más expects según los elementos clave
  });
}

