import 'package:flutter/material.dart';

// Tema claro (día)

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5), // Gris claro
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
    elevation: 4,
    shadowColor: Colors.grey,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFF5F5F5), // Gris claro
    selectedItemColor: Color(0xFFF44336), // rojo fuerte
    unselectedItemColor: Colors.black54, // gris oscuro
    selectedIconTheme: IconThemeData(size: 30),
    unselectedIconTheme: IconThemeData(size: 26),
    showUnselectedLabels: true,
    showSelectedLabels: true,
  ),
  cardTheme: CardThemeData(
    color: Colors.white, // fondo blanco
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
    ),
    shadowColor: Colors.red.shade200, // sombra suave
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF44336),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
    titleLarge: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white, // fondo blanco
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300), // borde rojo suave
    ),
    hintStyle: TextStyle(color: Colors.red.shade200), // rojo suave para el
    labelStyle: TextStyle(color: Colors.red.shade400), // rojo más oscuro para las etiquetas
  ),
);

// Tema oscuro (noche) con colores negros y buen contraste
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: const Color(0xFF0D0D0D), // Negro un poco más claro
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
    elevation: 6,
    shadowColor: Colors.black,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1C1C1C),
    selectedItemColor: Color(0xFFF44336), // rojo fuerte
    unselectedItemColor: Colors.white70,  // gris claro, no negro
    selectedIconTheme: IconThemeData(size: 30),
    unselectedIconTheme: IconThemeData(size: 26),
    showUnselectedLabels: true,
    showSelectedLabels: true,
  ),
  cardTheme: CardThemeData( // <-- Corrección aquí
    color: const Color(0xFF121212), // fondo negro suave
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
    ),
    shadowColor: Colors.red.shade900,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF44336),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    titleLarge: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1C1C1C), // gris oscuro para contraste
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade700),
    ),
    hintStyle: TextStyle(color: Colors.red.shade200),
    labelStyle: TextStyle(color: Colors.red.shade400),
  ),
);
