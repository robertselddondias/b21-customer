import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar {
  static void show({
    required String title,
    required String message,
    required SnackBarType type,
  }) {
    // Define cores e ícones com base no tipo de snackbar
    Color backgroundColor;
    IconData icon;
    Color textColor = AppColors.background;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppColors.darkModePrimary;
        icon = Icons.check_circle_outline;
        textColor = AppColors.primary;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = AppColors.ratingColour;
        icon = Icons.warning_amber_rounded;
        textColor = AppColors.primary;
        break;
    }

    // Configuração do snackbar
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP, // Posicionado no topo
      backgroundColor: backgroundColor,
      colorText: textColor,
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      icon: Icon(
        icon,
        color: textColor,
        size: 28,
      ),
      shouldIconPulse: true,
      duration: const Duration(seconds: 4), // Duração do snackbar
      animationDuration: const Duration(milliseconds: 300), // Animação suave
      barBlur: 8, // Efeito de desfoque
      overlayBlur: 1,
      overlayColor: Colors.black.withOpacity(0.1),
    );
  }
}

// Enum para tipos de snackbar
enum SnackBarType {
  success,
  error,
  warning,
}
