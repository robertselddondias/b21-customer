import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/driver_info_controller.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/credit_card_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/services/pagarme_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/orders/driver_info_screen.dart';
import 'package:customer/ui/orders/order_details_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetX<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
            child: Column(
              children: [
                // Header Section
                buildHeaderSection(controller),

                // Main Content Section
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Location Input Section
                                  buildDynamicLocationSection(context, controller),
                                  const SizedBox(height: 20),

                                  // Vehicle Selection Section
                                  buildVehicleSelection(context, controller),
                                  const SizedBox(height: 20),

                                  // Trip Details Section (Only if amount is populated)
                                  if (controller.amount.value.isNotEmpty)
                                    ...[
                                      buildTripDetailsSection(controller),
                                      const SizedBox(height: 20),
                                    ],

                                  // Payment Method Section
                                  buildPaymentSection(context, controller),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Confirm Button (Always at the bottom naturally)
                          buildConfirmButton(context, controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildHeaderSection(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bem-vindo, ${controller.userModel.value.fullName ?? ''}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Pronto para solicitar uma corrida?",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDynamicLocationSection(BuildContext context, HomeController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            SvgPicture.asset(
              'assets/icons/ic_source.svg',
              width: 18,
            ),
            Obx(() {
              final dynamicHeight = _calculateDynamicDashHeight(
                controller.sourceLocationController.value,
                controller.destinationLocationController.value,
                context,
              );
              return Dash(
                direction: Axis.vertical,
                length: dynamicHeight,
                dashLength: 12,
                dashColor: AppColors.dottedDivider,
              );
            }),
            SvgPicture.asset(
              'assets/icons/ic_destination.svg',
              width: 20,
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await _pickLocation(context, controller, isSource: true);
                },
                child: buildLocationInput(
                  context: context,
                  icon: Icons.my_location,
                  text: controller.sourceLocationController.value.isNotEmpty
                      ? controller.sourceLocationController.value
                      : 'Informe o local de partida',
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  await _pickLocation(context, controller, isSource: false);
                },
                child: buildLocationInput(
                  context: context,
                  icon: Icons.location_on,
                  text: controller.destinationLocationController.value.isNotEmpty
                      ? controller.destinationLocationController.value
                      : 'Informe o destino',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLocationInput({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textField,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTripDetailsSection(HomeController controller) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGray.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildTripDetailItem(
              icon: Icons.access_time,
              label: "Duração",
              value: controller.duration.value.isNotEmpty
                  ? controller.duration.value
                  : "--:--",
              backgroundColor: AppColors.serviceColor1,
              animationDelay: 300,
            ),
            buildTripDetailDivider(),
            buildTripDetailItem(
              icon: Icons.pin_drop,
              label: "Distância",
              value: controller.distance.value.isNotEmpty
                  ? "${controller.distance.value}"
                  : "-- km",
              backgroundColor: AppColors.serviceColor2,
              animationDelay: 400,
            ),
            buildTripDetailDivider(),
            buildTripDetailItem(
              icon: Icons.attach_money,
              label: "Valor",
              value: controller.amount.value.isNotEmpty
                  ? "R\$ ${controller.amount.value}"
                  : "R\$ --,--",
              backgroundColor: AppColors.serviceColor3,
              animationDelay: 500,
            ),
          ],
        ),
      );
    });
  }

  Widget buildTripDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
    required int animationDelay,
  }) {
    return Column(
      children: [
        TweenAnimationBuilder(
          duration: Duration(milliseconds: animationDelay),
          curve: Curves.easeInOut,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.subTitleColor,
          ),
        ),
      ],
    );
  }

  Widget buildTripDetailDivider() {
    return Container(
      width: 1,
      height: 70,
      color: AppColors.dottedDivider.withOpacity(0.2),
    );
  }

  Widget buildVehicleSelection(BuildContext context, HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha um veículo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lightGray
                : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: Responsive.height(18, context),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.serviceList.length,
            itemBuilder: (context, index) {
              final serviceModel = controller.serviceList[index];
              return Obx(() {
                final isSelected = controller.selectedType.value.id == serviceModel.id;
                return GestureDetector(
                  onTap: () {
                    controller.selectedType.value = serviceModel;
                    controller.calculateAmount();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: Responsive.width(28, context),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.gray,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(
                        color: isSelected ? AppColors.success : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: serviceModel.image ?? '',
                          fit: BoxFit.contain,
                          height: Responsive.height(8, context),
                          width: Responsive.width(18, context),
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          serviceModel.title ?? 'Sem título',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildPaymentSection(BuildContext context, HomeController controller) {
    return GestureDetector(
      onTap: () => _showPaymentMethodsDialog(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textFieldBorder, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/ic_payment.svg',
              width: 26,
            ),
            const SizedBox(width: 10),
            Obx(() => Expanded(
              child: Text(
                controller.selectedPaymentMethod.value.cardHolderName ??
                    'Selecione o método de pagamento',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            )),
            const Icon(Icons.arrow_drop_down_outlined),
          ],
        ),
      ),
    );
  }

  Widget buildConfirmButton(BuildContext context, HomeController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ElevatedButton(
        onPressed: () async {
          var result = await controller.createOrder();
          if(result) {
            showFindingDriverBottomSheet(context, controller);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? AppColors.darkModePrimary : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shadowColor: isDarkMode
              ? AppColors.darkGray.withOpacity(0.5)
              : AppColors.primary.withOpacity(0.5),
          elevation: 5,
        ),
        child: Text(
          'Solicitar Corrida',
          style: GoogleFonts.poppins(
            color: isDarkMode ? AppColors.darkGray : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  Future<void> _pickLocation(
      BuildContext context, HomeController controller, {required bool isSource}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey: Constant.mapAPIKey,
          initialPosition: const LatLng(-23.55052, -46.633308),
          useCurrentLocation: true,
          selectInitialPosition: true,
          usePinPointingSearch: true,
          usePlaceDetailSearch: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          resizeToAvoidBottomInset: false,
          region: '.br',
          autocompleteLanguage: 'pt-BR',
          autocompleteRadius: 200000,
          searchingText: 'Aguarde...',
          onPlacePicked: (result) {
            Navigator.of(context).pop();
            if (isSource) {
              controller.sourceLocationController.value = result.name ?? "";
              controller.sourceLocationLAtLng.value = LocationLatLng(
                latitude: result.geometry!.location.lat,
                longitude: result.geometry!.location.lng,
              );
            } else {
              controller.destinationLocationController.value = result.name ?? "";
              controller.destinationLocationLAtLng.value = LocationLatLng(
                latitude: result.geometry!.location.lat,
                longitude: result.geometry!.location.lng,
              );
            }
            controller.calculateAmount();
          },
        ),
      ),
    );
  }

  double _calculateDynamicDashHeight(
      String sourceText, String destinationText, BuildContext context) {
    final sourceHeight = _calculateTextHeight(sourceText, context);
    final destinationHeight = _calculateTextHeight(destinationText, context);

    return sourceHeight + destinationHeight + 20;
  }

  double _calculateTextHeight(String text, BuildContext context) {
    final textSpan = TextSpan(
      text: text,
      style: GoogleFonts.poppins(fontSize: 14),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 100);

    return textPainter.size.height;
  }

  void _showPaymentMethodsDialog(BuildContext context, HomeController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selecione o método de pagamento",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: controller.paymentModel.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.paymentModel.length) {
                    return ListTile(
                      leading: Icon(Icons.pix, color: Colors.green),
                      title: Text(
                        'Pagar com PIX',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      onTap: () {
                        controller.selectedPaymentMethod.value = CreditCardUserModel(
                          id: 'PIX',
                          cardHolderName: 'PIX',
                          transationalType: 'PIX',
                        );
                        controller.selectedPaymentMethod.refresh();
                        Navigator.pop(context);
                      },
                    );
                  }
                  final card = controller.paymentModel[index];
                  return ListTile(
                    leading: Icon(Icons.credit_card, color: Colors.blue),
                    title: Text(
                      '${card.cardHolderName} - ****${card.lastFourDigits}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    onTap: () {
                      controller.selectedPaymentMethod.value = card;
                      controller.selectedPaymentMethod.refresh();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showFindingDriverBottomSheet(BuildContext context, HomeController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.4,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(CollectionName.orders)
                  .doc(controller.orderModel.value.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'.tr));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Constant.loader();
                }

                controller.orderModel.value = OrderModel.fromJson(snapshot.data!.data()!);

                // NOVA LÓGICA: Detectar quando motorista aceita e processar pagamento automaticamente
                if (controller.orderModel.value.acceptedDriverId != null &&
                    controller.orderModel.value.acceptedDriverId!.isNotEmpty &&
                    controller.orderModel.value.status == Constant.ridePlaced) {

                  // Processar pagamento automaticamente
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _processAutomaticPaymentAndAcceptRide(context, controller);
                  });

                  return _buildPaymentProcessingUI(context, isDarkMode);
                }

                // LÓGICA ORIGINAL: Ainda procurando motorista
                if (controller.orderModel.value.acceptedDriverId == null) {
                  return _buildSearchingDriverUI(context, isDarkMode, controller);
                }

                // Se chegou aqui, algo inesperado aconteceu
                return _buildSearchingDriverUI(context, isDarkMode, controller);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _processAutomaticPaymentAndAcceptRide(BuildContext context, HomeController controller) async {
    try {
      ShowToastDialog.showLoader("Processando pagamento automaticamente...".tr);

      // Buscar dados do motorista que aceitou
      String acceptedDriverId = controller.orderModel.value.acceptedDriverId!.first;

      // Buscar dados do motorista
      DriverUserModel? driverModel = await FireStoreUtils.getDriver(acceptedDriverId);
      if (driverModel == null) {
        throw Exception('Motorista não encontrado');
      }

      // Buscar dados do usuário
      UserModel? userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (userModel == null) {
        throw Exception('Usuário não encontrado');
      }

      // Calcular valor da corrida
      double amount = await _calculateRideAmount(controller);

      // Processar pagamento
      await _processPayment(controller, amount);

      // Atualizar status da corrida para ativa
      await _activateRide(controller, acceptedDriverId, amount, driverModel);

      // Enviar notificação para o motorista
      await _sendDriverNotification(driverModel);

      ShowToastDialog.closeLoader();

      // Navegar para a tela de informações do motorista
      Navigator.pop(context); // Fechar o bottom sheet
      Get.to(const DriverInfoScreen(), arguments: {
        "orderModel": controller.orderModel.value,
      });

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao processar pagamento: ${e.toString()}");
      print("Erro no pagamento automático: $e");
    }
  }

// NOVA FUNÇÃO: Calcular valor da corrida
  Future<double> _calculateRideAmount(HomeController controller) async {
    try {
      var finalRate = controller.orderModel.value.offerRate ?? "0";
      return double.parse(finalRate.toString());
    } catch (e) {
      throw Exception('Erro ao calcular valor da corrida');
    }
  }

// NOVA FUNÇÃO: Processar pagamento
  Future<void> _processPayment(HomeController controller, double amount) async {
    PagarMeService pagarmeService = PagarMeService();

    if (controller.orderModel.value.creditCard != null) {
      var creditCard = controller.orderModel.value.creditCard;

      if (creditCard!.transationalType != 'PIX') {
        // Pagamento com cartão
        http.Response response = await pagarmeService.createOrder(
          amount: int.parse(amount.toString().replaceAll('.', '')),
          creditCard: creditCard,
          orderId: controller.orderModel.value.id!,
        );

        if (response.statusCode != 200) {
          throw Exception('Falha no pagamento com cartão');
        }
      } else {
        // Pagamento PIX
        http.Response response = await pagarmeService.createPixTransaction(
          amount: int.parse(amount.toString().replaceAll('.', '')),
          orderId: controller.orderModel.value.id!,
        );

        if (response.statusCode != 200) {
          throw Exception('Falha no pagamento PIX');
        }
      }

      // Registrar transação na carteira do usuário
      await _registerWalletTransaction(controller, amount);
    }
  }

// NOVA FUNÇÃO: Registrar transação na carteira
  Future<void> _registerWalletTransaction(HomeController controller, double amount) async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
      id: Constant.getUuid(),
      amount: "-$amount",
      createdDate: Timestamp.now(),
      paymentType: controller.orderModel.value.creditCard!.transationalType == 'credit' ? 'Cartão' : 'PIX',
      transactionId: controller.orderModel.value.id,
      note: "Valor da viagem débitada".tr,
      orderType: "city",
      userType: "customer",
      userId: FireStoreUtils.getCurrentUid(),
    );

    await FireStoreUtils.setWalletTransaction(transactionModel);
    await FireStoreUtils.updateUserWallet(amount: amount.toString());
  }

// NOVA FUNÇÃO: Ativar corrida
  Future<void> _activateRide(HomeController controller, String driverId, double amount, DriverUserModel driverModel) async {
    controller.orderModel.value.acceptedDriverId = [];
    controller.orderModel.value.driverId = driverId;
    controller.orderModel.value.status = Constant.rideActive;
    controller.orderModel.value.finalRate = amount.toString();

    await FireStoreUtils.setOrder(controller.orderModel.value);
  }

// NOVA FUNÇÃO: Enviar notificação para motorista
  Future<void> _sendDriverNotification(DriverUserModel driverModel) async {
    if (driverModel.fcmToken != null) {
      await SendNotification.sendOneNotification(
        token: driverModel.fcmToken.toString(),
        title: 'Corrida Confirmada'.tr,
        body: 'Sua solicitação de viagem foi aceita pelo passageiro. Por favor, prossiga para o local de retirada.'.tr,
        payload: {},
      );
    }
  }

// NOVA FUNÇÃO: UI para quando está processando pagamento
  Widget _buildPaymentProcessingUI(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de sucesso
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment,
              size: 40,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Motorista encontrado!",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.lightGray : AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          Text(
            "Processando pagamento automaticamente...",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? AppColors.lightGray : AppColors.subTitleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            strokeWidth: 4,
          ),
        ],
      ),
    );
  }

// NOVA FUNÇÃO: UI para quando ainda está procurando motorista (mantém original)
  Widget _buildSearchingDriverUI(BuildContext context, bool isDarkMode, HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mensagem e Loader
          Column(
            children: [
              Text(
                "Procurando um motorista...",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.lightGray : AppColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.success : AppColors.primary,
                ),
                strokeWidth: 4,
              ),
              const SizedBox(height: 20),
              Text(
                "Por favor, aguarde enquanto encontramos o melhor motorista para você.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.lightGray : AppColors.subTitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // Botão Cancelar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await controller.cancelTrip(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppColors.error : AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancelar Corrida',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
