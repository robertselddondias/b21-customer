import 'dart:async';
import 'package:get/get.dart';

class SearchTimerController extends GetxController {
  // Timer regressivo de 5 minutos (300 segundos)
  static const int _initialTimeInSeconds = 300;

  // Observáveis
  RxInt remainingSeconds = _initialTimeInSeconds.obs;
  RxBool isTimerActive = false.obs;
  RxString formattedTime = "05:00".obs;

  // Timer instance
  Timer? _countdownTimer;

  // Callback para quando o timer expira
  Function? onTimerExpired;

  @override
  void onInit() {
    super.onInit();
    _updateFormattedTime();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  /// Inicia o timer regressivo
  void startTimer({Function? onExpired}) {
    if (isTimerActive.value) return; // Evita múltiplos timers

    onTimerExpired = onExpired;
    isTimerActive.value = true;
    remainingSeconds.value = _initialTimeInSeconds;
    _updateFormattedTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _updateFormattedTime();
      } else {
        // Timer expirou
        _handleTimerExpiration();
      }
    });
  }

  /// Para o timer
  void stopTimer() {
    _countdownTimer?.cancel();
    isTimerActive.value = false;
  }

  /// Reseta o timer
  void resetTimer() {
    stopTimer();
    remainingSeconds.value = _initialTimeInSeconds;
    _updateFormattedTime();
  }

  /// Atualiza o formato de exibição do tempo (MM:SS)
  void _updateFormattedTime() {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    formattedTime.value = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// Manipula a expiração do timer
  void _handleTimerExpiration() {
    stopTimer();

    // Chama o callback se foi definido
    if (onTimerExpired != null) {
      onTimerExpired!();
    }
  }

  /// Verifica se o timer está próximo do fim (últimos 30 segundos)
  bool get isTimerCritical => remainingSeconds.value <= 30;

  /// Verifica se ainda há tempo suficiente (mais de 1 minuto)
  bool get hasGoodTime => remainingSeconds.value > 60;

  /// Porcentagem do progresso (0.0 a 1.0)
  double get progressPercentage =>
      (remainingSeconds.value / _initialTimeInSeconds).clamp(0.0, 1.0);
}