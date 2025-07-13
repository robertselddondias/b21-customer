import 'package:customer/model/credit_card_model.dart';
import 'package:customer/services/pagarme_service.dart';
import 'package:customer/utils/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CreditCardController extends GetxController {
  RxBool isLightTheme = false.obs;
  RxString cardNumber = ''.obs;
  RxString expiryDate = ''.obs;
  RxString cardHolderName = ''.obs;
  RxString cvvCode = ''.obs;
  RxBool isCvvFocused = false.obs;
  RxBool useGlassMorphism = false.obs;
  RxBool useBackgroundImage = false.obs;
  RxBool useFloatingAnimation = true.obs;
  RxBool isUpdated = false.obs;

  Rx<CreditCardUserModel> creditCardUpdated = CreditCardUserModel().obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  var tipoDocumento = 'CPF'.obs;
  var cardType = 'Crédito'.obs;

  RxBool isLoading = false.obs;

  final cpfController = TextEditingController();
  final apelidoController = TextEditingController();

  var cpfMaskFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  var cnpjMaskFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.grey.withOpacity(0.7),
      width: 2.0,
    ),
  );

  final PagarMeService _pagarMeService = PagarMeService();

  @override
  void onInit() async {
    await getArgument();
    super.onInit();
  }

  // Validação e envio dos dados do formulário
  Future<void> sendCreditCardToSave(themeChange, BuildContext context) async {
    try {
      // Chama o serviço para adicionar o cartão ao Pagar.me
      await _pagarMeService.createCard(
        cardNumber: cardNumber.value.removeAllWhitespace,
        cardHolderName: cardHolderName.value,
        cardExpirationDate: expiryDate.value,
        cardCvv: cvvCode.value,
        alias: apelidoController.text,
        documentNumber: cpfController.text,
        documentType: tipoDocumento.value,
      );

      // Exibe mensagem de sucesso
      CustomSnackBar.show(
        title: 'Sucesso',
        message: "Cartão adicionado com sucesso.",
        type: SnackBarType.success,
      );
    } catch (e) {
      // Exibe mensagem de erro
      CustomSnackBar.show(
        title: 'Erro',
        message: 'Cartão inserido é inválido, por favor verifique os dados informados.',
        type: SnackBarType.error,
      );
      print('Erro ao cadastrar cartão: $e');
    }
  }

  void onValidate() {
    if (formKey.currentState?.validate() ?? false) {
      print('valid!');
    } else {
      print('invalid!');
    }
  }

  Glassmorphism? getGlassmorphismConfig() {
    if (!useGlassMorphism.value) {
      return null;
    }

    final LinearGradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Colors.grey.withAlpha(50), Colors.grey.withAlpha(50)],
      stops: const <double>[0.3, 0],
    );

    return isLightTheme.value
        ? Glassmorphism(blurX: 8.0, blurY: 16.0, gradient: gradient)
        : Glassmorphism.defaultConfig();
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    cardNumber.value = creditCardModel.cardNumber;
    expiryDate.value = creditCardModel.expiryDate;
    cardHolderName.value = creditCardModel.cardHolderName;
    cvvCode.value = creditCardModel.cvvCode;
    isCvvFocused.value = creditCardModel.isCvvFocused;
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      creditCardUpdated.value = argumentData['creditCardSeletion'];
      isUpdated.value = argumentData['isUpdated'];
      if (isUpdated.value) {
        cardNumber.value = '000000000000${creditCardUpdated.value.lastFourDigits!}';
        expiryDate.value =
        '${creditCardUpdated.value.expirationMonth}/${creditCardUpdated.value.expirationYear.toString().replaceAll('20', '')}';
      }
    }
    update();
  }

  @override
  void onClose() {
    // Libera os controladores de texto ao fechar
    super.onClose();
    cpfController.dispose();
    apelidoController.dispose();
  }
}
