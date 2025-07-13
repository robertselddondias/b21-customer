import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/chat_screen/inbox_screen.dart';
import 'package:customer/ui/credit_card_screen/card_list_screen.dart';
import 'package:customer/ui/faq/faq_screen.dart';
import 'package:customer/ui/home_screens/home_screen.dart';
import 'package:customer/ui/orders/order_screen.dart';
import 'package:customer/ui/profile_screen/profile_screen.dart';
import 'package:customer/ui/referral_screen/referral_screen.dart';
import 'package:customer/ui/settings_screen/setting_screen.dart';
import 'package:customer/ui/wallet/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  final drawerItems = [
    DrawerItem('Home'.tr, "assets/icons/ic_city.svg"),
    DrawerItem('Corridas'.tr, "assets/icons/ic_order.svg"),
    DrawerItem('Minha Carteira'.tr, "assets/icons/ic_wallet.svg"),
    DrawerItem('Meios de Pagamentos'.tr, "assets/icons/ic_inbox.svg"),
    DrawerItem('Convide um Amigo'.tr, "assets/icons/ic_referral.svg"),
    DrawerItem('Mensagens'.tr, "assets/icons/ic_inbox.svg"),
    DrawerItem('Perfil'.tr, "assets/icons/ic_profile.svg"),
    // DrawerItem('Contact us'.tr, "assets/icons/ic_contact_us.svg"),
    DrawerItem('FAQs'.tr, "assets/icons/ic_faq.svg"),
    DrawerItem('Configurações'.tr, "assets/icons/ic_settings.svg"),
    DrawerItem('Sair'.tr, "assets/icons/ic_logout.svg"),
  ];

  getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return const HomeScreen();
      case 1:
        return const OrderScreen();
      case 2:
        return const WalletScreen();
      case 3:
        return CardListPage();
      case 4:
        return const ReferralScreen();
      case 5:
        return const InboxScreen();
      case 6:
        return const ProfileScreen();
      case 7:
        return const FaqScreen();
      case 8:
        return const SettingScreen();
      default:
        return const Text("Error");
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    if (index == 9) {
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
    Get.back();
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) > const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      ShowToastDialog.showToast("Double press to exit", position: EasyLoadingToastPosition.center);
      return Future.value(false);
    }
    return Future.value(true);
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
