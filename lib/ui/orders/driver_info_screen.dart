import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/driver_info_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverInfoScreen extends StatelessWidget {
  const DriverInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return GetX<DriverInfoController>(
      init: DriverInfoController(),
      builder: (controller) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
          body: controller.isLoading.value
              ? Constant.loader()
              : Column(
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    _buildMap(controller),
                    _buildMapOverlays(context, controller, isDarkMode, isTablet),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: _buildInfoSection(context, controller, isDarkMode, size, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(DriverInfoController controller) {
    return GoogleMap(
      onMapCreated: controller.onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(
          controller.orderModel.value.sourceLocationLAtLng?.latitude ?? 0.0,
          controller.orderModel.value.sourceLocationLAtLng?.longitude ?? 0.0,
        ),
        zoom: 14.0,
      ),
      markers: Set<Marker>.from(controller.markers.values),
      polylines: Set<Polyline>.from(controller.polyLines.values),
      myLocationEnabled: false,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildMapOverlays(BuildContext context, DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: _buildFloatingButton(
            onTap: () => Navigator.pop(context),
            icon: Icons.arrow_back_ios_new_rounded,
            isDarkMode: isDarkMode,
            isTablet: isTablet,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: _buildStatusBadge(controller, isDarkMode, isTablet),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 16,
          right: 16,
          child: _buildFloatingInfo(controller, isDarkMode, isTablet),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isDarkMode,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkContainerBackground.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : Colors.black87,
              size: isTablet ? 24 : 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: controller.rideStatusColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 8 : 6,
            height: isTablet ? 8 : 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            controller.rideStatusText,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInfo(DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_rounded,
            title: 'Chegada em',
            value: controller.estimatedTime.value.isNotEmpty
                ? controller.estimatedTime.value
                : '--',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.straighten_rounded,
            title: 'Distância',
            value: controller.estimatedDistance.value.isNotEmpty
                ? controller.estimatedDistance.value
                : '--',
            color: AppColors.success,
            isDarkMode: isDarkMode,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkContainerBackground.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8 : 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 10 : 8,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, DriverInfoController controller, bool isDarkMode, Size size, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkContainerBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDriverSection(controller, isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildTripSection(controller, isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildOTPSection(controller, isDarkMode, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildActionButtons(context, controller, isDarkMode, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection(DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBackground.withOpacity(0.5)
            : AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: isTablet ? 80 : 70,
                height: isTablet ? 80 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: controller.driverModel.value.profilePic ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.lightGray,
                      child: Icon(
                        Icons.person,
                        size: isTablet ? 40 : 35,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightGray,
                      child: Icon(
                        Icons.person,
                        size: isTablet ? 40 : 35,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: isTablet ? 24 : 20,
                  height: isTablet ? 24 : 20,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkContainerBackground : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: isTablet ? 12 : 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.driverModel.value.fullName ?? 'Motorista',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: double.parse(
                        Constant.calculateReview(
                          reviewCount: controller.driverModel.value.reviewsCount ?? '0.0',
                          reviewSum: controller.driverModel.value.reviewsSum ?? '0.0',
                        ),
                      ),
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: AppColors.ratingColour,
                      ),
                      itemCount: 5,
                      itemSize: isTablet ? 16 : 14,
                    ),
                    SizedBox(width: isTablet ? 8 : 6),
                    Text(
                      Constant.calculateReview(
                        reviewCount: controller.driverModel.value.reviewsCount ?? '0.0',
                        reviewSum: controller.driverModel.value.reviewsSum ?? '0.0',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: isTablet ? 16 : 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    SizedBox(width: isTablet ? 6 : 4),
                    Expanded(
                      child: Text(
                        '${controller.driverModel.value.vehicleInformation?.vehicleType ?? 'N/A'} • ${controller.driverModel.value.vehicleInformation?.vehicleNumber ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 12 : 10,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSection(DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações da Viagem',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.darkBackground.withOpacity(0.3)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: isTablet ? 12 : 10,
                    height: isTablet ? 12 : 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partida',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 12 : 10,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          controller.orderModel.value.sourceLocationName ?? 'Local de partida',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
                height: isTablet ? 30 : 25,
                child: Row(
                  children: [
                    SizedBox(width: isTablet ? 6 : 5),
                    Container(
                      width: 2,
                      height: double.infinity,
                      color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: isTablet ? 12 : 10,
                    height: isTablet ? 12 : 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destino',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 12 : 10,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          controller.orderModel.value.destinationLocationName ?? 'Local de destino',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Row(
          children: [
            Expanded(
              child: _buildTripInfoCard(
                icon: Icons.route_rounded,
                title: 'Distância Total',
                value: '${controller.orderModel.value.distance ?? '--'} km',
                color: AppColors.serviceColor1,
                isDarkMode: isDarkMode,
                isTablet: isTablet,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: _buildTripInfoCard(
                icon: Icons.payments_rounded,
                title: 'Valor',
                value: 'R\$ ${controller.orderModel.value.finalRate ?? controller.orderModel.value.offerRate ?? '--'}',
                color: AppColors.serviceColor2,
                isDarkMode: isDarkMode,
                isTablet: isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 10 : 8,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOTPSection(DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            const Color(0xFF4C1D95).withOpacity(0.3),
            const Color(0xFF7C3AED).withOpacity(0.1),
          ]
              : [
            const Color(0xFF7C3AED).withOpacity(0.1),
            const Color(0xFF4C1D95).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: const Color(0xFF7C3AED),
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                'Código de Verificação',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: controller.orderModel.value.otp ?? ''));
              ShowToastDialog.showToast('Código copiado!');
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.orderModel.value.otp ?? '----',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                      letterSpacing: isTablet ? 6 : 4,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Icon(
                    Icons.copy_rounded,
                    color: const Color(0xFF7C3AED),
                    size: isTablet ? 20 : 16,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Toque para copiar • Forneça este código ao motorista',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 11 : 9,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DriverInfoController controller, bool isDarkMode, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onTap: () => _makePhoneCall(controller.driverModel.value.phoneNumber ?? ''),
            icon: Icons.phone_rounded,
            label: 'Ligar',
            color: AppColors.success,
            isDarkMode: isDarkMode,
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: _buildActionButton(
            onTap: () => _openChat(context, controller),
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDarkMode,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 20 : 18,
            ),
            SizedBox(width: isTablet ? 8 : 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      await Constant.makePhoneCall(phoneNumber);
    }
  }

  void _openChat(BuildContext context, DriverInfoController controller) {
    Get.to(const ChatScreens(), arguments: {
      "customerName": controller.driverModel.value.fullName,
      "customerImage": controller.driverModel.value.profilePic,
      "customerId": controller.driverModel.value.id,
      "orderId": controller.orderModel.value.id,
      "customerToken": controller.driverModel.value.fcmToken,
    });
  }
}
