class PixPaymentModel {
  final String qrCodeUrl;
  final String copyCode;
  final String amount; // Valor em reais
  final DateTime expiresAt;

  PixPaymentModel({
    required this.qrCodeUrl,
    required this.copyCode,
    required this.amount,
    required this.expiresAt,
  });
}
