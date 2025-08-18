import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/dueño/restaurante_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodmaps/config/theme_provider.dart';

void main() {
  testWidgets('RestauranteSelectorScreen se construye correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: RestauranteSelectorScreen(restaurantes: const []),
        ),
      ),
    );
    expect(find.byType(RestauranteSelectorScreen), findsOneWidget);
    // Puedes agregar más expects según los elementos clave
  });
}
