import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/orders/order_details_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(horizontal: size.width * 0.04);

    return Scaffold(
      backgroundColor: themeChange.getThem() ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, themeChange, size),
            Expanded(
              child: _buildMainContent(context, themeChange, size, padding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DarkThemeProvider themeChange, Size size) {
    return Container(
      height: size.height * 0.12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeChange.getThem()
              ? [AppColors.darkBackground, AppColors.darkBackground.withOpacity(0.9)]
              : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Center(
        child: Text(
          "Minhas Corridas",
          style: GoogleFonts.inter(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, DarkThemeProvider themeChange, Size size, EdgeInsets padding) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size.width * 0.08),
          topRight: Radius.circular(size.width * 0.08),
        ),
        boxShadow: themeChange.getThem() ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            _buildTabBar(context, themeChange, size, padding),
            Expanded(
              child: Padding(
                padding: padding,
                child: TabBarView(
                  children: [
                    _buildActiveRidesTab(context, themeChange, size),
                    _buildCompletedRidesTab(context, themeChange, size),
                    _buildCanceledRidesTab(context, themeChange, size),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, DarkThemeProvider themeChange, Size size, EdgeInsets padding) {
    return Container(
      margin: padding.copyWith(top: size.height * 0.02, bottom: 0),
      height: size.height * 0.06,
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(
          color: themeChange.getThem()
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size.width * 0.035),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: themeChange.getThem() ? Colors.white60 : Colors.black54,
        labelStyle: GoogleFonts.inter(
          fontSize: size.width * 0.032,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: size.width * 0.032,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          _buildTab("Ativas", Icons.directions_car_rounded, size),
          _buildTab("Finalizadas", Icons.check_circle_rounded, size),
          _buildTab("Canceladas", Icons.cancel_rounded, size),
        ],
      ),
    );
  }

  Widget _buildTab(String text, IconData icon, Size size) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size.width * 0.04),
          if (size.width > 320) ...[
            SizedBox(width: size.width * 0.015),
            Flexible(
              child: Text(
                text.tr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveRidesTab(BuildContext context, DarkThemeProvider themeChange, Size size) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where("userId", isEqualTo: FireStoreUtils.getCurrentUid())
          .where("status", whereIn: [
        Constant.ridePlaced,
        Constant.rideInProgress,
        Constant.rideComplete,
        Constant.rideActive
      ])
          .where("paymentStatus", isEqualTo: false)
          .orderBy("createdDate", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(themeChange, size);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(themeChange, size);
        }
        return snapshot.data!.docs.isEmpty
            ? _buildEmptyState(themeChange, "Nenhuma corrida ativa", Icons.directions_car_outlined, size)
            : _buildRidesList(context, snapshot.data!.docs, themeChange, size, "active");
      },
    );
  }

  Widget _buildCompletedRidesTab(BuildContext context, DarkThemeProvider themeChange, Size size) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where("userId", isEqualTo: FireStoreUtils.getCurrentUid())
          .where("status", isEqualTo: Constant.rideComplete)
          .where("paymentStatus", isEqualTo: true)
          .orderBy("createdDate", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(themeChange, size);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(themeChange, size);
        }
        return snapshot.data!.docs.isEmpty
            ? _buildEmptyState(themeChange, "Nenhuma corrida finalizada", Icons.check_circle_outline, size)
            : _buildRidesList(context, snapshot.data!.docs, themeChange, size, "completed");
      },
    );
  }

  Widget _buildCanceledRidesTab(BuildContext context, DarkThemeProvider themeChange, Size size) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where("userId", isEqualTo: FireStoreUtils.getCurrentUid())
          .where("status", isEqualTo: Constant.rideCanceled)
          .orderBy("createdDate", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(themeChange, size);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(themeChange, size);
        }
        return snapshot.data!.docs.isEmpty
            ? _buildEmptyState(themeChange, "Nenhuma corrida cancelada", Icons.cancel_outlined, size)
            : _buildRidesList(context, snapshot.data!.docs, themeChange, size, "canceled");
      },
    );
  }

  Widget _buildLoadingState(DarkThemeProvider themeChange, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.16,
            height: size.width * 0.16,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size.width * 0.08,
                height: size.width * 0.08,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            "Carregando corridas...",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
              color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DarkThemeProvider themeChange, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.06),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: size.width * 0.12,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            "Algo deu errado",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            "Tente novamente mais tarde",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.035,
              color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DarkThemeProvider themeChange, String message, IconData icon, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.08),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: size.width * 0.12,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            "Suas corridas aparecerão aqui",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.035,
              color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList(BuildContext context, List<QueryDocumentSnapshot> docs,
      DarkThemeProvider themeChange, Size size, String tabType) {
    return ListView.builder(
      itemCount: docs.length,
      padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
      itemBuilder: (context, index) {
        OrderModel orderModel = OrderModel.fromJson(docs[index].data() as Map<String, dynamic>);
        return _buildRideCard(context, orderModel, themeChange, size, tabType);
      },
    );
  }

  Widget _buildRideCard(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange, Size size, String tabType) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      decoration: BoxDecoration(
        gradient: themeChange.getThem()
            ? LinearGradient(
          colors: [
            AppColors.darkContainerBackground,
            AppColors.darkContainerBackground.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.05),
        border: Border.all(
          color: themeChange.getThem()
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeChange.getThem() ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.05),
          onTap: () => _handleCardTap(orderModel),
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.045),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //_buildCardHeader(orderModel, themeChange, size),
                SizedBox(height: size.height * 0.02),
                if (orderModel.status == Constant.rideComplete ||
                    orderModel.status == Constant.rideActive ||
                    tabType == "completed") ...[
                  DriverView(
                    driverId: orderModel.driverId.toString(),
                    amount: orderModel.status == Constant.ridePlaced
                        ? double.parse(orderModel.offerRate.toString())
                        .toStringAsFixed(Constant.currencyModel!.decimalDigits!)
                        : double.parse(orderModel.finalRate?.toString() ?? "0.0")
                        .toStringAsFixed(Constant.currencyModel!.decimalDigits!),
                  ),
                  SizedBox(height: size.height * 0.02),
                ],
                LocationView(
                  sourceLocation: orderModel.sourceLocationName.toString(),
                  destinationLocation: orderModel.destinationLocationName.toString(),
                ),
                SizedBox(height: size.height * 0.02),
                if (orderModel.someOneElse != null)
                  _buildSomeoneElseSection(orderModel, themeChange, size),
                if (orderModel.status == Constant.rideActive)
                  _buildImprovedOtpSection(orderModel, themeChange, size),
                _buildTimeInfo(orderModel, themeChange, size),
                SizedBox(height: size.height * 0.015),
                _buildActionButtons(context, orderModel, themeChange, size, tabType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImprovedStatusSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    final statusText = _getStatusText(orderModel.status);
    final showOtp = orderModel.status == Constant.rideActive;

    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.025),
      child: Column(
        children: [
          if (showOtp)
            _buildImprovedOtpSection(orderModel, themeChange, size)
          else
            _buildImprovedInfoSection(statusText, themeChange, size),

          SizedBox(height: size.height * 0.015),

          // Seção de tempo separada
          _buildTimeInfo(orderModel, themeChange, size),
        ],
      ),
    );
  }

  Widget _buildImprovedOtpSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header do OTP
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.03),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: size.width * 0.045,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔐 Código de Segurança",
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.038,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    Text(
                      "Compartilhe com o motorista",
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.03,
                        fontWeight: FontWeight.w500,
                        color: themeChange.getThem() ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.02),

          // Container do código
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.width * 0.03,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size.width * 0.03),
              border: Border.all(
                color: const Color(0xFF7C3AED),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "${orderModel.otp}",
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.w900,
                    fontSize: size.width * 0.08,
                    color: const Color(0xFF7C3AED),
                    letterSpacing: 8,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(size.width * 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: size.width * 0.03,
                      ),
                      SizedBox(width: size.width * 0.02),
                      Text(
                        "Verificado",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.028,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.015),

          // Dica de uso
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(size.width * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(size.width * 0.025),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFFF59E0B),
                  size: size.width * 0.035,
                ),
                SizedBox(width: size.width * 0.025),
                Expanded(
                  child: Text(
                    "Forneça este código para confirmar sua identidade",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.028,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedInfoSection(String statusText, DarkThemeProvider themeChange, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: themeChange.getThem()
            ? LinearGradient(
          colors: [
            AppColors.darkBackground.withOpacity(0.4),
            AppColors.darkBackground.withOpacity(0.2),
          ],
        )
            : LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(
          color: themeChange.getThem()
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: size.width * 0.045,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: size.width * 0.035,
                color: themeChange.getThem() ? Colors.white : Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size.width * 0.025),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: size.width * 0.035,
            color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
          ),
          SizedBox(width: size.width * 0.02),
          Text(
            Constant().formatTimestamp(orderModel.createdDate),
            style: GoogleFonts.inter(
              fontSize: size.width * 0.028,
              fontWeight: FontWeight.w500,
              color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildCardHeader(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
  //   final statusInfo = _getStatusInfo(orderModel.status);
  //
  //   return Container(
  //     padding: EdgeInsets.all(size.width * 0.025),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           statusInfo['color'].withOpacity(0.1),
  //           statusInfo['color'].withOpacity(0.05),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(size.width * 0.03),
  //       border: Border.all(
  //         color: statusInfo['color'].withOpacity(0.2),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(size.width * 0.025),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [
  //                 statusInfo['color'],
  //                 statusInfo['color'].withOpacity(0.8),
  //               ],
  //             ),
  //             shape: BoxShape.circle,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: statusInfo['color'].withOpacity(0.3),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Icon(
  //             statusInfo['icon'],
  //             color: Colors.white,
  //             size: size.width * 0.045,
  //           ),
  //         ),
  //         SizedBox(width: size.width * 0.03),
  //         Expanded(
  //           flex: 2,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 statusInfo['title'],
  //                 style: GoogleFonts.inter(
  //                   fontSize: size.width * 0.04,
  //                   fontWeight: FontWeight.w700,
  //                   color: themeChange.getThem() ? Colors.white : Colors.black87,
  //                 ),
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               Text(
  //                 statusInfo['subtitle'],
  //                 style: GoogleFonts.inter(
  //                   fontSize: size.width * 0.03,
  //                   fontWeight: FontWeight.w500,
  //                   color: themeChange.getThem() ? Colors.white60 : Colors.grey[600],
  //                 ),
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(width: size.width * 0.02),
  //         Flexible(
  //           child: Container(
  //             padding: EdgeInsets.symmetric(
  //               horizontal: size.width * 0.025,
  //               vertical: size.width * 0.015,
  //             ),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [
  //                   AppColors.primary,
  //                   AppColors.primary.withOpacity(0.8),
  //                 ],
  //               ),
  //               borderRadius: BorderRadius.circular(size.width * 0.03),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: AppColors.primary.withOpacity(0.3),
  //                   blurRadius: 6,
  //                   offset: const Offset(0, 2),
  //                 ),
  //               ],
  //             ),
  //             child: Text(
  //               orderModel.status == Constant.ridePlaced
  //                   ? Constant.amountShow(
  //                   amount: double.parse(orderModel.offerRate.toString())
  //                       .toStringAsFixed(Constant.currencyModel!.decimalDigits!))
  //                   : Constant.amountShow(
  //                   amount: double.parse(orderModel.finalRate?.toString() ?? "0.0")
  //                       .toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
  //               style: GoogleFonts.inter(
  //                 fontWeight: FontWeight.w700,
  //                 fontSize: size.width * 0.028,
  //                 color: Colors.white,
  //               ),
  //               overflow: TextOverflow.ellipsis,
  //               textAlign: TextAlign.center,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSomeoneElseSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.serviceColor1.withOpacity(0.15),
            AppColors.serviceColor1.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        border: Border.all(
          color: AppColors.serviceColor1.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.025),
            decoration: BoxDecoration(
              color: AppColors.serviceColor1.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.serviceColor1,
              size: size.width * 0.045,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Passageiro:",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.028,
                    fontWeight: FontWeight.w500,
                    color: AppColors.serviceColor1.withOpacity(0.8),
                  ),
                ),
                Text(
                  orderModel.someOneElse!.fullName.toString(),
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.serviceColor1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.02,
              vertical: size.width * 0.01,
            ),
            decoration: BoxDecoration(
              color: AppColors.serviceColor1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size.width * 0.02),
            ),
            child: Text(
              orderModel.someOneElse!.contactNumber.toString(),
              style: GoogleFonts.inter(
                fontSize: size.width * 0.028,
                fontWeight: FontWeight.w600,
                color: AppColors.serviceColor1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    final statusText = _getStatusText(orderModel.status);
    final showOtp = orderModel.status == Constant.rideActive;

    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        gradient: themeChange.getThem()
            ? LinearGradient(
          colors: [
            AppColors.darkBackground.withOpacity(0.4),
            AppColors.darkBackground.withOpacity(0.2),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.08),
            Colors.grey.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        border: Border.all(
          color: themeChange.getThem()
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: showOtp
                ? _buildOtpSection(orderModel, themeChange, size)
                : _buildInfoSection(statusText, themeChange, size),
          ),
          _buildTimeSection(orderModel, themeChange, size),
        ],
      ),
    );
  }

  Widget _buildOtpSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.025),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.15),
            const Color(0xFF8B5CF6).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.025),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: size.width * 0.04,
                ),
              ),
              SizedBox(width: size.width * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔐 Código de Segurança",
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.03,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    Text(
                      "Compartilhe com o motorista",
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.025,
                        fontWeight: FontWeight.w500,
                        color: themeChange.getThem() ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.012),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.width * 0.025,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(size.width * 0.025),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: const Color(0xFF7C3AED),
                    size: size.width * 0.035,
                  ),
                  SizedBox(width: size.width * 0.015),
                  Text(
                    "${orderModel.otp}",
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w800,
                      fontSize: size.width * 0.055,
                      color: const Color(0xFF7C3AED),
                      letterSpacing: 4,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(width: size.width * 0.015),
                  GestureDetector(
                    onTap: () {
                      // Implementar cópia para clipboard
                      // Clipboard.setData(ClipboardData(text: orderModel.otp.toString()));
                      // ShowToastDialog.showToast("Código copiado!");
                    },
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.01),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(size.width * 0.015),
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        color: const Color(0xFF7C3AED),
                        size: size.width * 0.03,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: size.height * 0.008),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.025,
                vertical: size.width * 0.01,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(size.width * 0.02),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: const Color(0xFF10B981),
                    size: size.width * 0.025,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    "Verificado e Seguro",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.022,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String statusText, DarkThemeProvider themeChange, Size size) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(size.width * 0.02),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: size.width * 0.04,
          ),
        ),
        SizedBox(width: size.width * 0.025),
        Expanded(
          child: Text(
            statusText,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: size.width * 0.032,
              color: themeChange.getThem() ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.02,
        vertical: size.width * 0.015,
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(size.width * 0.02),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: size.width * 0.03,
            color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
          ),
          SizedBox(height: size.width * 0.005),
          Text(
            Constant().formatTimestamp(orderModel.createdDate),
            style: GoogleFonts.inter(
              fontSize: size.width * 0.022,
              fontWeight: FontWeight.w500,
              color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange, Size size, String tabType) {
    if (tabType == "completed") {
      return _buildReviewButton(context, orderModel, size);
    }

    if (tabType == "canceled") {
      return const SizedBox();
    }

    if (orderModel.status == Constant.ridePlaced) {
      return _buildConfirmButton(context, orderModel, size);
    }

    if (orderModel.status == Constant.rideComplete && orderModel.paymentStatus == null) {
      return _buildPayButton(context, orderModel, size);
    }

    if (orderModel.status == Constant.rideInProgress) {
      return Column(
        children: [
          _buildChatCallButtons(context, orderModel, size),
          SizedBox(height: size.height * 0.015),
          _buildSosButton(context, orderModel, size),
          SizedBox(height: size.height * 0.015),
          _buildTrackingButton(context, orderModel, size),
        ],
      );
    }

    if (orderModel.status == Constant.rideActive || orderModel.status == Constant.rideComplete) {
      return Column(
        children: [
          _buildChatCallButtons(context, orderModel, size),
          SizedBox(height: size.height * 0.015),
          _buildTrackingButton(context, orderModel, size),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildTrackingButton(BuildContext context, OrderModel orderModel, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Roxo moderno para rastreamento
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          onTap: () {
            Get.to(const LiveTrackingScreen(), arguments: {
              "type": "orderModel",
              "orderModel": orderModel,
            });
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                Text(
                  "Rastrear Corrida",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, OrderModel orderModel, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          onTap: () {
            Get.to(const OrderDetailsScreen(), arguments: {
              "orderModel": orderModel,
            });
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                Text(
                  "Confirmar Corrida",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, OrderModel orderModel, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          onTap: () {
            Get.to(const PaymentOrderScreen(), arguments: {
              "orderModel": orderModel,
            });
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                Text(
                  "Pagar Corrida",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSosButton(BuildContext context, OrderModel orderModel, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          onTap: () async {
            await FireStoreUtils.getSOS(orderModel.id.toString()).then((value) {
              if (value != null) {
                ShowToastDialog.showToast(
                  "Sua solicitação está ${value.status}",
                  position: EasyLoadingToastPosition.bottom,
                );
              } else {
                SosModel sosModel = SosModel();
                sosModel.id = Constant.getUuid();
                sosModel.orderId = orderModel.id;
                sosModel.status = "Initiated";
                sosModel.orderType = "city";
                FireStoreUtils.setSOS(sosModel);
              }
            });
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                Text(
                  "SOS Emergência",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, OrderModel orderModel, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.06,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amarelo dourado moderno para avaliação
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          onTap: () {
            Get.to(const ReviewScreen(), arguments: {
              "orderModel": orderModel,
            });
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.025),
                Text(
                  "Avaliar Corrida",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCallButtons(BuildContext context, OrderModel orderModel, Size size) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: size.height * 0.055,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)], // Azul moderno para Chat
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size.width * 0.025),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(size.width * 0.025),
                onTap: () {
                  Get.to(const ChatScreens(), arguments: {
                    "customerName": "Cliente",
                    "customerId": orderModel.userId,
                    "driverId": orderModel.driverId,
                    "orderId": orderModel.id,
                  });
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: size.width * 0.04,
                      ),
                      if (size.width > 320) ...[
                        SizedBox(width: size.width * 0.02),
                        Flexible(
                          child: Text(
                            "Chat",
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.032,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.025),
        Expanded(
          child: Container(
            height: size.height * 0.055,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF16A34A), const Color(0xFF22C55E)], // Verde moderno para Ligar
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size.width * 0.025),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(size.width * 0.025),
                onTap: () {
                  // Implementar lógica de chamada
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_rounded,
                        color: Colors.white,
                        size: size.width * 0.04,
                      ),
                      if (size.width > 320) ...[
                        SizedBox(width: size.width * 0.02),
                        Flexible(
                          child: Text(
                            "Ligar",
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.032,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  // Widget _buildImprovedOtpSection(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
  //   return Container(
  //     width: double.infinity,
  //     margin: EdgeInsets.only(bottom: size.height * 0.02),
  //     padding: EdgeInsets.all(size.width * 0.04),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           const Color(0xFF7C3AED).withOpacity(0.1),
  //           const Color(0xFF8B5CF6).withOpacity(0.05),
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(size.width * 0.04),
  //       border: Border.all(
  //         color: const Color(0xFF7C3AED).withOpacity(0.3),
  //         width: 1.5,
  //       ),
  //     ),
  //     child: Column(
  //       children: [
  //         // Header do OTP
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(size.width * 0.03),
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   colors: [
  //                     const Color(0xFF7C3AED),
  //                     const Color(0xFF8B5CF6),
  //                   ],
  //                 ),
  //                 shape: BoxShape.circle,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: const Color(0xFF7C3AED).withOpacity(0.4),
  //                     blurRadius: 12,
  //                     offset: const Offset(0, 4),
  //                   ),
  //                 ],
  //               ),
  //               child: Icon(
  //                 Icons.security_rounded,
  //                 color: Colors.white,
  //                 size: size.width * 0.045,
  //               ),
  //             ),
  //             SizedBox(width: size.width * 0.03),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     "🔐 Código de Segurança",
  //                     style: GoogleFonts.inter(
  //                       fontSize: size.width * 0.038,
  //                       fontWeight: FontWeight.w700,
  //                       color: const Color(0xFF7C3AED),
  //                     ),
  //                   ),
  //                   Text(
  //                     "Compartilhe com o motorista",
  //                     style: GoogleFonts.inter(
  //                       fontSize: size.width * 0.03,
  //                       fontWeight: FontWeight.w500,
  //                       color: themeChange.getThem() ? Colors.white60 : Colors.grey[600],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         SizedBox(height: size.height * 0.02),
  //
  //         // Container do código
  //         Container(
  //           width: double.infinity,
  //           padding: EdgeInsets.symmetric(
  //             horizontal: size.width * 0.04,
  //             vertical: size.width * 0.03,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(size.width * 0.03),
  //             border: Border.all(
  //               color: const Color(0xFF7C3AED),
  //               width: 2,
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: const Color(0xFF7C3AED).withOpacity(0.15),
  //                 blurRadius: 12,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               Text(
  //                 "${orderModel.otp}",
  //                 style: GoogleFonts.robotoMono(
  //                   fontWeight: FontWeight.w900,
  //                   fontSize: size.width * 0.08,
  //                   color: const Color(0xFF7C3AED),
  //                   letterSpacing: 8,
  //                   fontFeatures: [FontFeature.tabularFigures()],
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: size.height * 0.01),
  //               Container(
  //                 padding: EdgeInsets.symmetric(
  //                   horizontal: size.width * 0.03,
  //                   vertical: size.width * 0.015,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   gradient: LinearGradient(
  //                     colors: [
  //                       const Color(0xFF10B981),
  //                       const Color(0xFF059669),
  //                     ],
  //                   ),
  //                   borderRadius: BorderRadius.circular(size.width * 0.05),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       Icons.verified_user_rounded,
  //                       color: Colors.white,
  //                       size: size.width * 0.03,
  //                     ),
  //                     SizedBox(width: size.width * 0.02),
  //                     Text(
  //                       "Verificado",
  //                       style: GoogleFonts.inter(
  //                         fontSize: size.width * 0.028,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //
  //         SizedBox(height: size.height * 0.015),
  //
  //         // Dica de uso
  //         Container(
  //           width: double.infinity,
  //           padding: EdgeInsets.all(size.width * 0.025),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFFEF3C7),
  //             borderRadius: BorderRadius.circular(size.width * 0.025),
  //             border: Border.all(
  //               color: const Color(0xFFF59E0B).withOpacity(0.3),
  //             ),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.info_outline_rounded,
  //                 color: const Color(0xFFF59E0B),
  //                 size: size.width * 0.035,
  //               ),
  //               SizedBox(width: size.width * 0.025),
  //               Expanded(
  //                 child: Text(
  //                   "Forneça este código para confirmar sua identidade",
  //                   style: GoogleFonts.inter(
  //                     fontSize: size.width * 0.028,
  //                     fontWeight: FontWeight.w500,
  //                     color: const Color(0xFFD97706),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTimeInfo(OrderModel orderModel, DarkThemeProvider themeChange, Size size) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(size.width * 0.03),
  //     decoration: BoxDecoration(
  //       color: themeChange.getThem()
  //           ? Colors.white.withOpacity(0.08)
  //           : Colors.grey.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(size.width * 0.025),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(
  //           Icons.access_time_rounded,
  //           size: size.width * 0.035,
  //           color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
  //         ),
  //         SizedBox(width: size.width * 0.02),
  //         Text(
  //           Constant().formatTimestamp(orderModel.createdDate),
  //           style: GoogleFonts.inter(
  //             fontSize: size.width * 0.028,
  //             fontWeight: FontWeight.w500,
  //             color: themeChange.getThem() ? Colors.white70 : Colors.grey[600],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Helper methods
  Map<String, dynamic> _getStatusInfo(String? status) {
    switch (status) {
      case Constant.ridePlaced:
        return {
          'title': 'Corrida Solicitada',
          'subtitle': 'Aguardando confirmação',
          'icon': Icons.schedule_rounded,
          'color': AppColors.primary,
        };
      case Constant.rideActive:
        return {
          'title': 'Corrida Ativa',
          'subtitle': 'Motorista a caminho',
          'icon': Icons.directions_car_rounded,
          'color': AppColors.serviceColor1,
        };
      case Constant.rideInProgress:
        return {
          'title': 'Em Andamento',
          'subtitle': 'Viagem em progresso',
          'icon': Icons.navigation_rounded,
          'color': AppColors.serviceColor2,
        };
      case Constant.rideComplete:
        return {
          'title': 'Corrida Concluída',
          'subtitle': 'Viagem finalizada',
          'icon': Icons.check_circle_rounded,
          'color': AppColors.success,
        };
      case Constant.rideCanceled:
        return {
          'title': 'Corrida Cancelada',
          'subtitle': 'Viagem cancelada',
          'icon': Icons.cancel_rounded,
          'color': AppColors.error,
        };
      default:
        return {
          'title': 'Status Desconhecido',
          'subtitle': 'Verificando status',
          'icon': Icons.help_outline_rounded,
          'color': Colors.grey,
        };
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case Constant.ridePlaced:
        return 'Aguardando confirmação do motorista';
      case Constant.rideActive:
        return 'Motorista confirmado e a caminho';
      case Constant.rideInProgress:
        return 'Viagem em andamento';
      case Constant.rideComplete:
        return 'Viagem concluída com sucesso';
      case Constant.rideCanceled:
        return 'Viagem foi cancelada';
      default:
        return 'Status não identificado';
    }
  }

  void _handleCardTap(OrderModel orderModel) {
    if (orderModel.status == Constant.rideInProgress || orderModel.status == Constant.rideActive) {
      Get.to(const LiveTrackingScreen(), arguments: {
        "type": "orderModel",
        "orderModel": orderModel,
      });
    } else if (orderModel.status == Constant.rideComplete) {
      Get.to(const CompleteOrderScreen(), arguments: {
        "orderModel": orderModel,
      });
    } else {
      Get.to(const OrderDetailsScreen(), arguments: {
        "orderModel": orderModel,
      });
    }
  }
}