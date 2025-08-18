import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/screens/dueño/maps_due_activity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodmaps/config/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodmaps/screens/login_screen.dart';

void main() {
  testWidgets('MapsDueActivity se construye correctamente', (WidgetTester tester) async {
    // Mockear SharedPreferences con token para evitar navegación automática al login
    SharedPreferences.setMockInitialValues({
      'token': 'mock_token',
      'restaurante_id': 1,
      'restaurantes': '[{"id":1,"nombre":"Restaurante 1"}]',
      'restaurante_seleccionado': 1,
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: MapsDueActivity(restauranteId: 1),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle(); // Esperar a que se completen animaciones y timers
    expect(find.byType(MapsDueActivity), findsOneWidget);
  });
}
