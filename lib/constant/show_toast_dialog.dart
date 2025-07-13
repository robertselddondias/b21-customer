import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ShowToastDialog {
  // Configuração de loader com suporte ao modo noturno e cor personalizada
  static configureLoader({bool isDarkMode = false}) {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = isDarkMode
          ? AppColors.darkBackground.withOpacity(0.9) // Fundo escuro
          : AppColors.lightGray.withOpacity(0.9) // Fundo claro
      ..indicatorColor = Colors.transparent // Indicador personalizado
      ..textColor = isDarkMode ? AppColors.darkModePrimary : AppColors.primary
      ..toastPosition = EasyLoadingToastPosition.center
      ..progressColor = Colors.transparent
      ..maskColor = isDarkMode
          ? AppColors.darkBackground.withOpacity(0.6)
          : AppColors.lightGray.withOpacity(0.6)
      ..maskType = EasyLoadingMaskType.black
      ..animationStyle = EasyLoadingAnimationStyle.opacity
      ..displayDuration = const Duration(milliseconds: 2000)
      ..userInteractions = false
      ..customAnimation = CustomLoaderAnimation(); // Animação personalizada
  }

  static showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) {
    EasyLoading.showToast(
      message!,
      toastPosition: position,
    );
  }

  static showLoader(String message) {
    EasyLoading.show(
      status: message,
      indicator: CleanGradientIndicator(), // Indicador clean
    );
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}

// Indicador clean e moderno com a cor do AppColors
class CleanGradientIndicator extends StatelessWidget {
  const CleanGradientIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(AppColors.darkModePrimary), // Cor substituída
            backgroundColor: AppColors.lightGray, // Fundo do indicador
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkGray, // Um círculo central para equilíbrio
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animação suave para o loader
class CustomLoaderAnimation extends EasyLoadingAnimation {
  @override
  Widget buildWidget(
      Widget child,
      AnimationController controller,
      AlignmentGeometry alignment,
      ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut, // Suavidade
      ),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutExpo, // Transição limpa
        ),
        child: child,
      ),
    );
  }
}
