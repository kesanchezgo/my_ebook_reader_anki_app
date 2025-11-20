import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumToast {
  static void show(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    Color iconColor;

    if (isError) {
      backgroundColor = isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020);
      textColor = Colors.white;
      icon = Icons.error_outline_rounded;
      iconColor = Colors.white;
    } else if (isSuccess) {
      backgroundColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF018786);
      textColor = Colors.black; // Better contrast on teal
      icon = Icons.check_circle_outline_rounded;
      iconColor = Colors.black;
    } else {
      // Default / Info
      backgroundColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
      icon = Icons.info_outline_rounded;
      iconColor = theme.colorScheme.primary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20), // Más margen
        elevation: 0, 
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 3),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16), // Más redondeado
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.7), // Más transparente (Glassmorphism)
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
