import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  
  static const Color primary = Color(0xFF3B82F6);    // Blue 500
  static const Color primaryLight = Color(0xFF60A5FA); // Blue 400
  
  static const Color accent = Colors.orangeAccent;
  
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF2979FF);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textFaded = Color(0xFF94A3B8);  // Slate 400 - mejor para texto de "placeholder"
  static const Color background54 = Colors.black54; // Fondo oscuro semitransparente para superposición
}
