import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/credit_card_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/payment_processing_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OrderDetailsController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    getUser();
    super.onInit();
  }

  Completer<void> completer = Completer<void>();

  Rx<UserModel> userModel = UserModel().obs;
  Rx<OrderModel> orderModel = OrderModel().obs;
  RxString couponAmount = "0.0".obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<CreditCardUserModel> selectedPaymentMethod = CreditCardUserModel().obs;
  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Rx<DriverIdAcceptReject> driverIdAcceptReject = DriverIdAcceptReject().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    update();
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
  }

  Future<double> calculateAmount() async{
    try {
      RxString taxAmount = "0.0".obs;
      if (orderModel.value.taxList != null) {
        for (var element in orderModel.value.taxList!) {
          taxAmount.value = (double.parse(taxAmount.value) +
              Constant().calculateTax(
                  amount: (double.parse(orderModel.value.finalRate.toString()) -
                      double.parse(couponAmount.value.toString())).toString(),
                  taxModel: element))
              .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
        }
      }
      var finalRate = orderModel.value.finalRate!;
      return (double.parse(finalRate) -
          double.parse(couponAmount.value.toString())) +
          double.parse(taxAmount.value);
    } catch(e) {
      throw Exception('Erro ao pesquisar Order');
    }
  }

  getPaymentData() async {
    selectedPaymentMethod.value = orderModel.value.creditCard!;

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
    await FireStoreUtils.getDriver(orderModel.value.driverId.toString()).then((value) {
      if (value != null) {
        driverUserModel.value = value;
      }
    });
    update();
  }

  completePaymentoOrder(BuildContext context) async {
    orderModel.value.acceptedDriverId = [];
    orderModel.value.driverId = driverIdAcceptReject.value.driverId.toString();
    orderModel.value.status = Constant.rideActive;
    orderModel.value.finalRate = driverIdAcceptReject.value.offerAmount;
    // orderModel.paymentStatus = true;
    await FireStoreUtils.setOrder(orderModel.value);
    var amount = await calculateAmount();
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: "-$amount",
        createdDate: Timestamp.now(),
        paymentType: orderModel.value.creditCard!.transationalType == 'credit' ? 'Cartão' : 'PIX',
        transactionId: orderModel.value.id,
        note: "Valor da viagem débitada".tr,
        orderType: "city",
        userType: "customer",
        userId: FireStoreUtils.getCurrentUid());
    //
    await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
      double amount = await calculateAmount();
      if (value == true) {
        await FireStoreUtils.updateUserWallet(amount: amount.toString()).then((value) {
          completeOrder();
        });
      }

    });

    await SendNotification.sendOneNotification(
        token: driverModel.value.fcmToken.toString(),
        title: 'Corrida Confirmada'.tr,
        body: 'Sua solicitação de viagem foi aceita pelo passageiro. Por favor, prossiga para o local de retirada.'.tr,
        payload: {});
    completer.complete();
  }

  completeOrder() async {
    ShowToastDialog.showLoader("Please wait...".tr);
    // orderModel.value.paymentStatus = true;
    orderModel.value.creditCard = selectedPaymentMethod.value;
    // orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;
    orderModel.value.updateDate = Timestamp.now();

    var amount = await calculateAmount();

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amount.toString(),
        createdDate: Timestamp.now(),
        paymentType: orderModel.value.creditCard!.transationalType == 'credit' ? 'Cartão' : 'PIX',
        transactionId: orderModel.value.id,
        userId: orderModel.value.driverId.toString(),
        orderType: "city",
        userType: "driver",
        note: "Valor da corrida foi creditada");

    await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
      double amount = await calculateAmount();
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(amount: amount.toString(), driverId: orderModel.value.driverId.toString());
      }
    });

    var amountComission = Constant.calculateOrderAdminCommission(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())).toString(), adminCommission: orderModel.value.adminCommission);
    WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
        id: Constant.getUuid(),
        amount:
        "-$amountComission",
        createdDate: Timestamp.now(),
        paymentType: orderModel.value.creditCard!.transationalType == 'credit' ? 'Cartão' : 'PIX',
        transactionId: orderModel.value.id,
        orderType: "city",
        userType: "driver",
        userId: orderModel.value.driverId.toString(),
        note: "Taxa de administração da b-21 foi debitada da sua carteira.");

    await FireStoreUtils.setWalletTransaction(adminCommissionWallet).then((value) async {
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(
            amount:
            "-${Constant.calculateOrderAdminCommission(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())).toString(), adminCommission: orderModel.value.adminCommission)}",
            driverId: orderModel.value.driverId.toString());
      }
    });

    if (driverUserModel.value.fcmToken != null) {
      Map<String, dynamic> playLoad = <String, dynamic>{"type": "city_order_payment_complete", "orderId": orderModel.value.id};

      await SendNotification.sendOneNotification(
          token: driverUserModel.value.fcmToken.toString(),
          title: 'Payment Received',
          body: '${userModel.value.fullName}  has paid ${Constant.amountShow(amount: calculateAmount().toString())} for the completed ride.Check your earnings for details.',
          payload: playLoad);
    }

    await FireStoreUtils.getFirestOrderOrNOt(orderModel.value).then((value) async {
      if (value == true) {
        await FireStoreUtils.updateReferralAmount(orderModel.value);
      }
    });

    await FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride Complete successfully");
      }
    });
  }

  Future<String?> decodeQrCodeFromUrl(String qrCodeUrl) async {
    try {
      // Baixa a imagem do QR Code
      final response = await http.get(Uri.parse(qrCodeUrl));
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar o QR Code');
      }

      // Salva a imagem em um arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_qrcode.png');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Decodifica o QR Code para string
      final qrCodeData = null;//await QrCodeToolsPlugin.decodeFrom(tempFile.path);

      // Retorna o conteúdo do QR Code
      return qrCodeData;
    } catch (e) {
      print('Erro ao decodificar o QR Code: $e');
      return null;
    }
  }

  Future<void> listenToNewTransactions(String orderId, BuildContext context) async {
    FirebaseFirestore.instance
        .collection('transaction_pagarme')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        // Verifica se o registro foi adicionado
        if (change.type == DocumentChangeType.added) {
          final newData = change.doc.data();
          if (newData?['orderId'] == orderId) {
            await completePaymentoOrder(context);
          }
        }
      }
    }, onError: (error) {
      print('Erro ao monitorar a coleção: $error');
      Get.snackbar(
        'Erro',
        'Não foi possível monitorar as transações.',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  void showProcessingLoader(BuildContext context, Completer<void> completer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentProcessingLoader(completer: completer),
    );
  }
}
