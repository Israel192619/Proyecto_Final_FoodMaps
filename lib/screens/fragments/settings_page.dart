import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding de 16dp
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrado vertical
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity, // Match parent
              child: ElevatedButton(
                onPressed: () {
                  // Acción para agregar negocio
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Agregar mi negocio"),
              ),
            ),
            const SizedBox(height: 16), // Margen entre botones
            SizedBox(
              width: double.infinity, // Match parent
              child: ElevatedButton(
                onPressed: () {
                  // Acción para cerrar sesión
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Cerrar Sesión"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}