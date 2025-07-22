import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/controller/search_timer_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/credit_card_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/services/pagarme_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/custom_snack_bar.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/geoflutterfire/geoflutterfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<String> sourceLocationController = ''.obs;
  Rx<String> destinationLocationController = ''.obs;
  Rx<TextEditingController> offerYourRateController = TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  final SearchTimerController searchTimer = Get.put(SearchTimerController());

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxList bannerList = <BannerModel>[].obs;
  RxList zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxInt selectedCardIndex = 0.obs;

  RxBool isSearchTimerRunning = false.obs;

  Rx<OrderModel> orderModel = OrderModel().obs;

  RxBool isSelected = true.obs;

  RxBool isProcessingPayment = false.obs;

  Rx<DriverUserModel> acceptedDriverModel = DriverUserModel().obs;

  final PageController pageController = PageController(viewportFraction: 0.96, keepPage: true);

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  @override
  void onInit() {
    selectedCardIndex.value = -1;
    getServiceType();
    getPaymentData();
    super.onInit();
  }

  @override
  void onClose() {
    // 🆕 APENAS ADICIONAR - Cleanup do timer
    if (isSearchTimerRunning.value) {
      searchTimer.stopTimer();
    }
    super.onClose();
  }

  Future<bool> createOrder() async {
    bool isPaymentNotCompleted = await FireStoreUtils.paymentStatusCheck();

    var distanceDouble = double.parse(distance.value.isNotEmpty ? distance.value.replaceAll(' km', '') : '0.0');

    if (sourceLocationController.value.isEmpty) {
      CustomSnackBar.show(
        title: 'Atenção',
        message: 'Selecione o local de origem.'.tr,
        type: SnackBarType.warning,
      );
    } else if (destinationLocationController.value.isEmpty) {
      CustomSnackBar.show(
        title: 'Atenção',
        message: 'Selecione o local de destino.'.tr,
        type: SnackBarType.warning,
      );
    } else if (distanceDouble <= 1) {
      CustomSnackBar.show(
        title: 'Atenção',
        message: 'A distância precisa ser maior que 2km.'.tr,
        type: SnackBarType.warning,
      );
    } else if (selectedType.value.offerRate == true && offerYourRateController.value.text.isEmpty) {
      CustomSnackBar.show(
        title: 'Atenção',
        message: 'Conclua o pagamento da corrida anterior antes de prosseguir.'.tr,
        type: SnackBarType.warning,
      );
    } else if (selectedPaymentMethod.value.cardHolderName == null || selectedPaymentMethod.value.cardHolderName!.isEmpty) {
      CustomSnackBar.show(
        title: 'Atenção',
        message: 'Selecione o método de pagamento.'.tr,
        type: SnackBarType.warning,
      );
    } else {
      orderModel.value.id = Constant.getUuid();
      orderModel.value.userId = FireStoreUtils.getCurrentUid();
      orderModel.value.sourceLocationName = sourceLocationController.value;
      orderModel.value.destinationLocationName = destinationLocationController.value;
      orderModel.value.sourceLocationLAtLng = sourceLocationLAtLng.value;
      orderModel.value.destinationLocationLAtLng = destinationLocationLAtLng.value;
      orderModel.value.distance = distanceDouble.toString();
      orderModel.value.distanceType = Constant.distanceType;
      orderModel.value.offerRate =
      selectedType.value.offerRate == true ? offerYourRateController.value.text : amount.value;
      orderModel.value.serviceId = selectedType.value.id;
      GeoFirePoint position = Geoflutterfire()
          .point(latitude: sourceLocationLAtLng.value.latitude!, longitude: sourceLocationLAtLng.value.longitude!);

      orderModel.value.position = Positions(geoPoint: position.geoPoint, geohash: position.hash);
      orderModel.value.createdDate = Timestamp.now();
      orderModel.value.status = Constant.ridePlaced;
      orderModel.value.creditCard = selectedPaymentMethod.value;
      orderModel.value.paymentStatus = false;
      orderModel.value.service = selectedType.value;
      orderModel.value.adminCommission = selectedType.value.adminCommission!.isEnabled == false
          ? selectedType.value.adminCommission!
          : Constant.adminCommission;
      orderModel.value.otp = Constant.getReferralCode();
      orderModel.value.taxList = Constant.taxList;

      for (int i = 0; i < zoneList.length; i++) {
        print("====>");
        print(sourceLocationLAtLng.value.latitude.toString());
        print(sourceLocationLAtLng.value.longitude.toString());
        if (Constant.isPointInPolygon(
            LatLng(double.parse(sourceLocationLAtLng.value.latitude.toString()),
                double.parse(sourceLocationLAtLng.value.longitude.toString())),
            zoneList[i].area!)) {
          selectedZone.value = zoneList[i];
          orderModel.value.zoneId = selectedZone.value.id;
          orderModel.value.zone = selectedZone.value;
          FireStoreUtils().sendOrderData(orderModel.value).listen((event) {
            event.forEach((element) async {
              if (element.fcmToken != null) {
                Map<String, dynamic> playLoad = <String, dynamic>{"type": "city_order", "orderId": orderModel.value.id};
                await SendNotification.sendOneNotification(
                    token: element.fcmToken.toString(),
                    title: 'Nova corrida disponível'.tr,
                    body: 'Um motorista agendou uma viagem perto de sua localização.'.tr,
                    payload: playLoad);
              }
            });
            FireStoreUtils().closeStream();
          });
          await FireStoreUtils.setOrder(orderModel.value).then((value) {
            ShowToastDialog.showToast("Corrida enviada com sucesso".tr);
            dashboardController.selectedDrawerIndex(1);
            ShowToastDialog.closeLoader();
          });
          break;
        } else {
          ShowToastDialog.showToast(
              "Os serviços não estão disponíveis no local selecionado no momento. Entre em contato com o administrador para obter assistência.",
              position: EasyLoadingToastPosition.center);
        }
        return false;
      }
      return true;
    }
    return false;
  }

  void getServiceType() async {
    // Supondo que os serviços vêm de uma API ou Firestore
    final services = await FireStoreUtils.getService();
    if (services.isNotEmpty) {
      serviceList.value = services;
      isSelected.value = true;
      selectedType.value = services.first; // Seleciona o primeiro serviço por padrão
    }

    try {
      Constant.currentLocation = await Utils.getCurrentLocation();

      if (Constant.currentLocation != null) {
        if (Constant.selectedMapType == 'google') {
          List<Placemark> placeMarks = await placemarkFromCoordinates(Constant.currentLocation!.latitude, Constant.currentLocation!.longitude);
          print("=====>");
          print(placeMarks.first);
          Constant.country = placeMarks.first.country;
          Constant.city = placeMarks.first.locality;
          currentLocation.value =
          "${placeMarks.first.name}, ${placeMarks.first.subLocality}, ${placeMarks.first.locality}";
        } else {
          Place place = await Nominatim.reverseSearch(
            lat: Constant.currentLocation!.latitude,
            lon: Constant.currentLocation!.longitude,
            zoom: 14,
            addressDetails: true,
            extraTags: true,
            nameDetails: true,
          );
          currentLocation.value = place.displayName.toString();
          Constant.country = place.address?['country'] ?? '';
          Constant.city = place.address?['city'] ?? '';
        }
        await FireStoreUtils().getTaxList().then((value) {
          if (value != null) {
            Constant.taxList = value;
          }
        });
      }
    } catch (e) {
      print("=====>");
      print(e.toString());
      ShowToastDialog.showToast(
          "A permissão de acesso à localização não está disponível no momento. Você não consegue recuperar nenhum dado de localização. Conceda permissão nas configurações do seu dispositivo.",
          position: EasyLoadingToastPosition.center);
    }

    String token = await NotificationService.getToken();
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
      userModel.value = value!;
      userModel.value.fcmToken = token;
      FireStoreUtils.updateUser(userModel.value);
    });

    isLoading.value = false;
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;

  void calculateAmount() async {
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      final result = await Constant.getDurationDistance(
        LatLng(sourceLocationLAtLng.value.latitude!,
            sourceLocationLAtLng.value.longitude!),
        LatLng(destinationLocationLAtLng.value.latitude!,
            destinationLocationLAtLng.value.longitude!),
      );

      if (result != null) {
        final distanceDb = result.rows!.first.elements!.first.distance!.value!;
        distance.value = result.rows!.first.elements!.first.distance!.text!;
        duration.value = result.rows!.first.elements!.first!.duration!.text!;
        amount.value = Constant.amountCalculate(
          selectedType.value.kmCharge.toString(),
          (distanceDb / 1000).toString(),
        ).toStringAsFixed(Constant.currencyModel!.decimalDigits!);
        print('Novo valor calculado: $amount');
      }
    }
  }

  void updateSelectedType(ServiceModel service) {
    if (selectedType.value.id != service.id) {
      selectedType.value = service;
      calculateAmount();
      print('Selecionado: ${service.title}');
    }
  }

  RxList<CreditCardUserModel> paymentModel = RxList<CreditCardUserModel>([]);

  Rx<CreditCardUserModel> selectedPaymentMethod = CreditCardUserModel().obs;

  RxList airPortList = <AriPortModel>[].obs;

  getPaymentData() async {
    await FireStoreUtils.getAllCreditCard(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        paymentModel.value = value;
      }

    });

    await FireStoreUtils().getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });
  }


  Future<void> cancelTrip(BuildContext context) async {
    List<dynamic> acceptDriverId = [];

    // Reset das variáveis do pagamento automático
    isProcessingPayment.value = false;
    acceptedDriverModel.value = DriverUserModel();

    orderModel.value.status = Constant.rideCanceled;
    orderModel.value.acceptedDriverId = acceptDriverId;
    await FireStoreUtils.setOrder(orderModel.value).then((value) {
      Navigator.pop(context);
    });
  }

  void resetForNewRide() {
    isProcessingPayment.value = false;
    acceptedDriverModel.value = DriverUserModel();
    orderModel.value = OrderModel();
  }


  Future<double> calculateAutomaticRideAmount() async {
    try {
      var finalRate = orderModel.value.offerRate ?? "0";
      return double.parse(finalRate.toString());
    } catch (e) {
      throw Exception('Erro ao calcular valor da corrida');
    }
  }

  // NOVA FUNÇÃO: Processar pagamento automático quando motorista aceita
  Future<void> processAutomaticPayment() async {
    try {
      if (isProcessingPayment.value) return; // Evitar processamento duplo

      isProcessingPayment.value = true;

      // Buscar motorista que aceitou
      if (orderModel.value.acceptedDriverId != null &&
          orderModel.value.acceptedDriverId!.isNotEmpty) {

        String driverId = orderModel.value.acceptedDriverId!.first;

        // Buscar dados do motorista
        DriverUserModel? driver = await FireStoreUtils.getDriver(driverId);
        if (driver != null) {
          acceptedDriverModel.value = driver;
        }

        // Calcular valor
        double amount = await calculateAutomaticRideAmount();

        // Processar pagamento
        await _executePayment(amount);

        // Ativar corrida
        await _activateRideAutomatically(driverId, amount);

        // Enviar notificação
        if (driver?.fcmToken != null) {
          await _sendAcceptanceNotification(driver!);
        }
      }

    } catch (e) {
      print("Erro no processamento automático: $e");
      throw e;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  // NOVA FUNÇÃO: Executar pagamento
  Future<void> _executePayment(double amount) async {
    PagarMeService pagarmeService = PagarMeService();

    if (orderModel.value.creditCard != null) {
      var creditCard = orderModel.value.creditCard!;

      if (creditCard.transationalType != 'PIX') {
        // Pagamento com cartão
        http.Response response = await pagarmeService.createOrder(
          amount: int.parse(amount.toString().replaceAll('.', '')),
          creditCard: creditCard,
          orderId: orderModel.value.id!,
        );

        if (response.statusCode != 200) {
          throw Exception('Falha no pagamento com cartão');
        }
      } else {
        // Pagamento PIX
        http.Response response = await pagarmeService.createPixTransaction(
          amount: int.parse(amount.toString().replaceAll('.', '')),
          orderId: orderModel.value.id!,
        );

        if (response.statusCode != 200) {
          throw Exception('Falha no pagamento PIX');
        }
      }

      // Registrar transação
      await _createWalletTransaction(amount);
    }
  }

  // NOVA FUNÇÃO: Criar transação na carteira
  Future<void> _createWalletTransaction(double amount) async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
      id: Constant.getUuid(),
      amount: "-$amount",
      createdDate: Timestamp.now(),
      paymentType: orderModel.value.creditCard!.transationalType == 'credit' ? 'Cartão' : 'PIX',
      transactionId: orderModel.value.id,
      note: "Valor da viagem débitada".tr,
      orderType: "city",
      userType: "customer",
      userId: FireStoreUtils.getCurrentUid(),
    );

    await FireStoreUtils.setWalletTransaction(transactionModel);
    await FireStoreUtils.updateUserWallet(amount: amount.toString());
  }

  // NOVA FUNÇÃO: Ativar corrida automaticamente
  Future<void> _activateRideAutomatically(String driverId, double amount) async {
    orderModel.value.acceptedDriverId = [];
    orderModel.value.driverId = driverId;
    orderModel.value.status = Constant.rideActive;
    orderModel.value.finalRate = amount.toString();

    await FireStoreUtils.setOrder(orderModel.value);
  }

  // NOVA FUNÇÃO: Enviar notificação de aceitação
  Future<void> _sendAcceptanceNotification(DriverUserModel driver) async {
    await SendNotification.sendOneNotification(
      token: driver.fcmToken.toString(),
      title: 'Corrida Confirmada'.tr,
      body: 'Sua solicitação de viagem foi aceita pelo passageiro. Por favor, prossiga para o local de retirada.'.tr,
      payload: {},
    );
  }

  // NOVA FUNÇÃO: Verificar se há motorista aceito (para usar na UI)
  bool hasAcceptedDriver() {
    return orderModel.value.acceptedDriverId != null &&
        orderModel.value.acceptedDriverId!.isNotEmpty;
  }

  // NOVA FUNÇÃO: Verificar se corrida está sendo processada
  bool isRideBeingProcessed() {
    return hasAcceptedDriver() &&
        orderModel.value.status == Constant.ridePlaced;
  }



}
