import 'package:customer/model/credit_card_model.dart';
import 'package:customer/utils/custom_snack_bar.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  RxList<CreditCardUserModel> customerCards = <CreditCardUserModel>[].obs;
  var selectedCard = {}.obs;
  var paymentStatus = ''.obs;

  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;
  RxString urlCardImage = ''.obs;
  RxInt index = 0.obs;

  Rx<CreditCardUserModel> creditCardSelection = CreditCardUserModel().obs;

  @override
  void onInit() async {
    await fetchCustomerCards();
    super.onInit();
  }

  // Método para listar todos os cartões de um cliente
  Future<void> fetchCustomerCards() async {
    try {
      isLoading.value = true;
      var result = await FireStoreUtils.getAllCreditCard(FireStoreUtils.getCurrentUid());

      if (result != null) {
        customerCards.value = result;
      }

      isLoading.value = false;
    } catch (e) {
      print("Erro ao listar cartões do cliente: $e");
      CustomSnackBar.show(
        title: "Erro",
        message: "Não foi possível listar os cartões.",
        type: SnackBarType.error,
      );
    }
  }

  // Método para buscar um cartão específico pelo customerId e cardId
  Future<void> fetchCardById(String customerId, String cardId) async {
    try {
      print("Cartão carregado com sucesso");
      CustomSnackBar.show(
        title: "Sucesso",
        message: "Cartão carregado com sucesso.",
        type: SnackBarType.success,
      );
    } catch (e) {
      print("Erro ao obter informações do cartão: $e");
      CustomSnackBar.show(
        title: "Erro",
        message: "Erro ao obter informações do cartão.",
        type: SnackBarType.error,
      );
    }
  }

  // Método para remover um cartão do cliente
  Future<void> removeCustomerCard(CreditCardUserModel card, BuildContext context) async {
    try {
      await FireStoreUtils.deleteCreditCard(card.id!);
      CustomSnackBar.show(
        title: "Sucesso",
        message: "Cartão excluído com sucesso.",
        type: SnackBarType.success,
      );
      fetchCustomerCards();
    } catch (e) {
      print("Erro ao remover o cartão: $e");
      CustomSnackBar.show(
        title: "Erro",
        message: "Erro ao excluir o cartão.",
        type: SnackBarType.error,
      );
    }
  }
}
