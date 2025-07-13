import 'package:flutter/material.dart';

class GlobalKeyboardDismiss extends StatelessWidget {
  final Widget child;

  const GlobalKeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Remove o foco (esconde o teclado)
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque, // Garante que toques fora sejam capturados
      child: child,
    );
  }
}
