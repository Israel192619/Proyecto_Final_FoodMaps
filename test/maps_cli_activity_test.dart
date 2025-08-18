import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/cliente/maps_cli_activity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodmaps/config/theme_provider.dart';

void main() {
  testWidgets('MapsCliActivity se construye correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: MapsCliActivity()),
      ),
    );
    expect(find.byType(MapsCliActivity), findsOneWidget);
    // Puedes agregar más expects según los elementos clave
  });
}
