import 'dart:async';

import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentProcessingLoader extends StatefulWidget {
  final Completer<void> completer;

  const PaymentProcessingLoader({super.key, required this.completer});

  @override
  State<PaymentProcessingLoader> createState() => _PaymentProcessingLoaderState();
}

class _PaymentProcessingLoaderState extends State<PaymentProcessingLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    widget.completer.future.then((_) {
      setState(() {
        isSuccess = true;
      });
      _animationController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 500),
          crossFadeState: isSuccess ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aguarde, estamos processando seu pagamento...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.lightGray : AppColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _animationController,
                child: Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: isDarkMode ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pagamento concluído com sucesso!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.lightGray : AppColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
