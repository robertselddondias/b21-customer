import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/controller/order_details_controller.dart';
import 'package:customer/model/driver_rules_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/pix_payment_model.dart';
import 'package:customer/services/pagarme_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../widget/driver_view.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GetBuilder<OrderDetailsController>(
        init: OrderDetailsController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: buildAppBar(context, isTablet),
            body: Column(
              children: [
                SizedBox(height: isTablet ? 12 : 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeChange.getThem() ? AppColors.darkGray : AppColors.gray,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isTablet ? 30 : 25),
                        topRight: Radius.circular(isTablet ? 30 : 25),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: isTablet ? 16 : 10),
                      child: buildStreamBuilder(context, controller, themeChange, isTablet, screenHeight),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  PreferredSizeWidget buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: isTablet ? 2 : 0,
      title: Text(
        "Ride Details".tr,
        style: TextStyle(
          fontSize: isTablet ? 20 : 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      leading: InkWell(
        onTap: () => Get.back(),
        child: Icon(
          Icons.arrow_back,
          size: isTablet ? 28 : 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildStreamBuilder(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet, double screenHeight) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(CollectionName.orders).doc(controller.orderModel.value.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong'.tr,
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Constant.loader());
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Center(
            child: Text(
              'No data available'.tr,
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          );
        }

        controller.orderModel.value = OrderModel.fromJson(snapshot.data!.data()!);
        return buildMainContent(context, controller, themeChange, isTablet, screenHeight);
      },
    );
  }

  Widget buildMainContent(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet, double screenHeight) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildOrderInfoSection(context, controller, themeChange, isTablet),
          buildDriversSection(context, controller, themeChange, isTablet),
        ],
      ),
    );
  }

  Widget buildOrderInfoSection(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildStatusRow(controller, isTablet),
          SizedBox(height: isTablet ? 16 : 10),
          LocationView(
            sourceLocation: controller.orderModel.value.sourceLocationName.toString(),
            destinationLocation: controller.orderModel.value.destinationLocationName.toString(),
          ),
          SizedBox(height: isTablet ? 16 : 10),
          buildOtpContainer(context, controller, themeChange, isTablet),
          SizedBox(height: isTablet ? 16 : 10),
          buildCancelButton(context, controller, isTablet),
        ],
      ),
    );
  }

  Widget buildStatusRow(OrderDetailsController controller, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Text(
            controller.orderModel.value.status.toString(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
        ),
        Text(
          controller.orderModel.value.status == Constant.ridePlaced
              ? Constant.amountShow(amount: controller.orderModel.value.offerRate.toString())
              : Constant.amountShow(amount: controller.orderModel.value.finalRate == null ? "0.0" : controller.orderModel.value.finalRate.toString()),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget buildOtpContainer(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBorder : Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 10,
          vertical: isTablet ? 18 : 14,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    "OTP".tr,
                    style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
                  ),
                  Text(
                    " : ${controller.orderModel.value.otp}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                Constant().formatTimestamp(controller.orderModel.value.createdDate),
                style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCancelButton(BuildContext context, OrderDetailsController controller, bool isTablet) {
    return ButtonThem.buildButton(
      context,
      title: "Cancel".tr,
      btnHeight: isTablet ? 52 : 44,
      onPress: () async {
        List<dynamic> acceptDriverId = [];
        controller.orderModel.value.status = Constant.rideCanceled;
        controller.orderModel.value.acceptedDriverId = acceptDriverId;
        await FireStoreUtils.setOrder(controller.orderModel.value).then((value) {
          Get.back();
        });
      },
    );
  }

  Widget buildDriversSection(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return controller.orderModel.value.acceptedDriverId == null || controller.orderModel.value.acceptedDriverId!.isEmpty
        ? Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Text(
          "No driver Found".tr,
          style: TextStyle(fontSize: isTablet ? 18 : 16),
        ),
      ),
    )
        : Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(top: isTablet ? 16 : 10),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.orderModel.value.acceptedDriverId!.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return buildDriverCard(context, controller, themeChange, isTablet, index);
        },
      ),
    );
  }

  Widget buildDriverCard(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet, int index) {
    return FutureBuilder<DriverUserModel?>(
      future: FireStoreUtils.getDriver(controller.orderModel.value.acceptedDriverId![index]),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Center(child: Constant.loader()),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Text(
                    'Driver not found'.tr,
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              );
            } else {
              controller.driverModel.value = snapshot.data!;
              return buildDriverDetailsCard(context, controller, themeChange, isTablet);
            }
          default:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Text(
                'Error'.tr,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            );
        }
      },
    );
  }

  Widget buildDriverDetailsCard(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return FutureBuilder<DriverIdAcceptReject?>(
      future: FireStoreUtils.getAcceptedOrders(
        controller.orderModel.value.id.toString(),
        controller.driverModel.value.id.toString(),
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Center(child: Constant.loader()),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Text(
                    'Order data not found'.tr,
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              );
            } else {
              controller.driverIdAcceptReject.value = snapshot.data!;
              return buildDriverInfoContainer(context, controller, themeChange, isTablet);
            }
          default:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Text(
                'Error'.tr,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            );
        }
      },
    );
  }

  Widget buildDriverInfoContainer(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 14,
        vertical: isTablet ? 12 : 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem() ? AppColors.darkContainerBackground : Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(
            color: themeChange.getThem()
                ? AppColors.darkContainerBorder.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: themeChange.getThem()
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header do Card com gradiente sutil
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeChange.getThem()
                      ? [
                    AppColors.darkContainerBackground,
                    AppColors.darkContainerBackground.withOpacity(0.8),
                  ]
                      : [
                    AppColors.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 20 : 16),
                  topRight: Radius.circular(isTablet ? 20 : 16),
                ),
              ),
              child: DriverView(
                driverId: controller.driverModel.value.id?.toString() ?? '',
                amount: controller.driverIdAcceptReject.value.offerAmount?.toString() ?? '0.0',
              ),
            ),

            // Seção de informações do veículo modernizada
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 20 : 16,
              ),
              child: Column(
                children: [
                  // Título da seção
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 8 : 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.primary,
                          size: isTablet ? 20 : 18,
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 10),
                      Text(
                        "Informações do Veículo",
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: themeChange.getThem() ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isTablet ? 16 : 12),

                  // Cards de informação do veículo em grid
                  Row(
                    children: [
                      Expanded(
                        child: buildModernVehicleInfoCard(
                          'assets/icons/ic_car.svg',
                          'Tipo',
                          controller.driverModel.value.vehicleInformation?.vehicleType?.toString() ?? 'N/A',
                          AppColors.serviceColor1.withOpacity(0.1),
                          AppColors.serviceColor1,
                          themeChange,
                          isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Expanded(
                        child: buildModernVehicleInfoCard(
                          'assets/icons/ic_color.svg',
                          'Cor',
                          controller.driverModel.value.vehicleInformation?.vehicleColor?.toString() ?? 'N/A',
                          AppColors.serviceColor2.withOpacity(0.1),
                          AppColors.serviceColor2,
                          themeChange,
                          isTablet,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isTablet ? 12 : 8),

                  // Placa em card destacado
                  buildModernVehicleInfoCard(
                    'assets/icons/ic_number.png',
                    'Placa',
                    controller.driverModel.value.vehicleInformation?.vehicleNumber?.toString() ?? 'N/A',
                    AppColors.serviceColor3.withOpacity(0.1),
                    AppColors.serviceColor3,
                    themeChange,
                    isTablet,
                    isAsset: true,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),

            // Seção de regras do motorista (se existir)
            if (controller.driverModel.value.vehicleInformation?.driverRules != null &&
                controller.driverModel.value.vehicleInformation!.driverRules!.isNotEmpty)
              buildModernDriverRules(context, controller, themeChange, isTablet),

            // Seção de botões de ação modernizada
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppColors.darkContainerBackground.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.02),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isTablet ? 20 : 16),
                  bottomRight: Radius.circular(isTablet ? 20 : 16),
                ),
              ),
              child: buildModernActionButtons(context, controller, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildModernVehicleInfoCard(
      String icon,
      String label,
      String value,
      Color backgroundColor,
      Color iconColor,
      DarkThemeProvider themeChange,
      bool isTablet, {
        bool isAsset = false,
        bool isFullWidth = false,
      }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isAsset
                    ? Image.asset(
                  icon,
                  width: isTablet ? 16 : 14,
                  height: isTablet ? 16 : 14,
                  color: iconColor,
                )
                    : SvgPicture.asset(
                  icon,
                  width: isTablet ? 16 : 14,
                  height: isTablet ? 16 : 14,
                  color: iconColor,
                ),
              ),
              if (isFullWidth) ...[
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),
          if (!isFullWidth)
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: isFullWidth ? TextAlign.start : TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildModernDriverRules(BuildContext context, OrderDetailsController controller,
      DarkThemeProvider themeChange, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 8 : 6,
      ),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground.withOpacity(0.3)
            : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: AppColors.success.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simples
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
                size: isTablet ? 18 : 16,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                "Serviços Disponíveis",
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 6 : 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${controller.driverModel.value.vehicleInformation!.driverRules!.length}",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 11 : 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 12 : 8),

          // Lista vertical de serviços
          ...controller.driverModel.value.vehicleInformation!.driverRules!
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final driverRule = entry.value;
            return buildServiceListItem(driverRule, themeChange, isTablet, index);
          }),
        ],
      ),
    );
  }

  Widget buildServiceListItem(DriverRulesModel driverRule, DarkThemeProvider themeChange,
      bool isTablet, int index) {

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 8 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone do serviço
          Container(
            width: isTablet ? 32 : 28,
            height: isTablet ? 32 : 28,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: driverRule.image?.toString() ?? '',
                width: isTablet ? 16 : 14,
                height: isTablet ? 16 : 14,
                color: AppColors.success,
                placeholder: (context, url) => SizedBox(
                  width: isTablet ? 16 : 14,
                  height: isTablet ? 16 : 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.check_circle_outline,
                  size: isTablet ? 16 : 14,
                  color: AppColors.success,
                ),
              ),
            ),
          ),

          SizedBox(width: isTablet ? 12 : 10),

          // Nome do serviço
          Expanded(
            child: Text(
              driverRule.name?.toString() ?? 'Serviço não especificado',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w500,
                color: themeChange.getThem() ? Colors.white : Colors.black87,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          // Indicador de disponível
          Container(
            width: isTablet ? 8 : 6,
            height: isTablet ? 8 : 6,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildModernActionButtons(BuildContext context, OrderDetailsController controller, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                onTap: () async {
                  await handleRejectDriver(controller);
                },
                child: SizedBox(
                  height: isTablet ? 52 : 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: isTablet ? 20 : 18,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        "Rejeitar".tr,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: isTablet ? 16 : 12),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                onTap: () async {
                  await handleAcceptDriver(context, controller, isTablet);
                },
                child: SizedBox(
                  height: isTablet ? 52 : 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 20 : 18,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        "Aceitar".tr,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Future<void> handleRejectDriver(OrderDetailsController controller) async {
    List<dynamic> rejectDriverId = controller.orderModel.value.rejectedDriverId ?? [];
    rejectDriverId.add(controller.driverModel.value.id);

    List<dynamic> acceptDriverId = controller.orderModel.value.acceptedDriverId ?? [];
    acceptDriverId.remove(controller.driverModel.value.id);

    controller.orderModel.value.rejectedDriverId = rejectDriverId;
    controller.orderModel.value.acceptedDriverId = acceptDriverId;

    await SendNotification.sendOneNotification(
      token: controller.driverModel.value.fcmToken.toString(),
      title: 'Ride Canceled'.tr,
      body: 'The passenger has canceled the ride. No action is required from your end.'.tr,
      payload: {},
    );
    await FireStoreUtils.setOrder(controller.orderModel.value);
  }

  Future<void> handleAcceptDriver(BuildContext context, OrderDetailsController controller, bool isTablet) async {
    PagarMeService pagarmeService = PagarMeService();
    http.Response response;

    if (controller.orderModel.value.creditCard != null) {
      var creditCard = controller.orderModel.value.creditCard;
      if (creditCard != null) {
        if (creditCard.transationalType != 'PIX') {
          controller.showProcessingLoader(context, controller.completer);
          response = await pagarmeService.createOrder(
            amount: int.parse(
              controller.orderModel.value.offerRate.toString().replaceAll('.', '').toString(),
            ),
            creditCard: controller.orderModel.value.creditCard!,
            orderId: controller.orderModel.value.id!,
          );
        } else {
          response = await pagarmeService.createPixTransaction(
            amount: int.parse(
              controller.orderModel.value.offerRate.toString().replaceAll('.', '').toString(),
            ),
            orderId: controller.orderModel.value.id!,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            var bodyPix = jsonDecode(response.body);
            if (bodyPix['status'] != 'failed') {
              var codePix = await controller.decodeQrCodeFromUrl(
                bodyPix['charges'][0]['last_transaction']['qr_code_url'],
              );
              pixPaymentDialog(
                context,
                controller,
                PixPaymentModel(
                  qrCodeUrl: bodyPix['charges'][0]['last_transaction']['qr_code_url'],
                  copyCode: codePix!,
                  amount: controller.orderModel.value.offerRate.toString(),
                  expiresAt: DateTime.now().add(Duration(minutes: 6)),
                ),
                isTablet,
              );
            }
          }
        }
        await controller.listenToNewTransactions(controller.orderModel.value.id!, context);
      }
    }
  }

  void pixPaymentDialog(BuildContext context, OrderDetailsController controller,
      PixPaymentModel pixPayment, bool isTablet) {
    final Rx<Duration> timeRemaining = pixPayment.expiresAt.difference(DateTime.now()).obs;

    Timer.periodic(Duration(seconds: 1), (timer) {
      final remaining = pixPayment.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
      } else {
        timeRemaining.value = remaining;
      }
    });

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(isTablet ? 20 : 15),
          topLeft: Radius.circular(isTablet ? 20 : 15),
        ),
      ),
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context1) {
        return FractionallySizedBox(
          heightFactor: isTablet ? 0.85 : 0.9,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 20 : 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildPixHeader(isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 24 : 16),
                  buildQrCodeSection(timeRemaining, pixPayment, isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 20 : 16),
                  Obx(() {
                    return timeRemaining.value.isNegative
                        ? SizedBox.shrink()
                        : Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12 : 8,
                        horizontal: isTablet ? 20 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkContainerBackground : AppColors.containerBackground,
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                      ),
                      child: Text(
                        "Tempo restante: ${timeRemaining.value.inMinutes}m ${timeRemaining.value.inSeconds % 60}s",
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.lightGray : AppColors.primary,
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: isTablet ? 20 : 16),
                  buildPixCodeSection(pixPayment, isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 20 : 16),
                  buildAmountSection(pixPayment, isDarkMode, isTablet),
                  const Spacer(),
                  buildCloseButton(isDarkMode, isTablet),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPixHeader(bool isDarkMode, bool isTablet) {
    return Center(
      child: Text(
        "Pagamento via Pix",
        style: TextStyle(
          fontSize: isTablet ? 26 : 22,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? AppColors.lightGray : AppColors.primary,
        ),
      ),
    );
  }

  Widget buildQrCodeSection(Rx<Duration> timeRemaining, PixPaymentModel pixPayment,
      bool isDarkMode, bool isTablet) {
    return Obx(() {
      if (!timeRemaining.value.isNegative) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkContainerBackground : AppColors.containerBackground,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              ),
              child: Image.network(
                pixPayment.qrCodeUrl,
                height: isTablet ? 240 : 200,
                width: isTablet ? 240 : 200,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      "Erro ao carregar QR Code",
                      style: TextStyle(
                        color: AppColors.ratingColour,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              "Escaneie o QR Code acima para realizar o pagamento",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: isDarkMode ? AppColors.lightGray : AppColors.subTitleColor,
              ),
            ),
          ],
        );
      } else {
        return Text(
          "Tempo expirado!",
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.ratingColour,
          ),
        );
      }
    });
  }

  Widget buildPixCodeSection(PixPaymentModel pixPayment, bool isDarkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkContainerBorder : AppColors.containerBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Código Pix:",
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.lightGray : AppColors.primary,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: pixPayment.copyCode));
              Get.snackbar(
                "Copiado!",
                "Código Pix copiado com sucesso.",
                backgroundColor: isDarkMode ? AppColors.darkContainerBackground : AppColors.containerBackground,
                colorText: isDarkMode ? AppColors.lightGray : AppColors.primary,
                icon: Icon(
                  Icons.check_circle,
                  color: isDarkMode ? AppColors.darkModePrimary : AppColors.primary,
                  size: isTablet ? 28 : 24,
                ),
                snackPosition: SnackPosition.TOP,
                margin: EdgeInsets.all(isTablet ? 20 : 16),
                duration: const Duration(seconds: 2),
              );
            },
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkTextField : AppColors.textField,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                border: Border.all(
                  color: isDarkMode ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pixPayment.copyCode,
                      overflow: TextOverflow.ellipsis,
                      maxLines: isTablet ? 2 : 1,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: isDarkMode ? AppColors.lightGray : AppColors.subTitleColor,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Icon(
                    Icons.copy,
                    color: isDarkMode ? AppColors.darkModePrimary : AppColors.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAmountSection(PixPaymentModel pixPayment, bool isDarkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkContainerBorder : AppColors.containerBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Valor:",
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.lightGray : AppColors.primary,
            ),
          ),
          Text(
            "R\$ ${pixPayment.amount}",
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkModePrimary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCloseButton(bool isDarkMode, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          ),
          backgroundColor: isDarkMode ? AppColors.darkModePrimary : AppColors.primary,
        ),
        child: Text(
          "Fechar",
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: isDarkMode ? AppColors.darkBackground : AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
