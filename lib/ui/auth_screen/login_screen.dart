import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            body: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem responsiva
                      SizedBox(
                        height: isLandscape
                            ? screenHeight * 0.3
                            : screenHeight * 0.35,
                        width: double.infinity,
                        child: Image.asset(
                          "assets/images/login_image.png",
                          fit: BoxFit.cover,
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? screenWidth * 0.1 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight * 0.02),

                              // Título responsivo
                              Text(
                                "Login".tr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 24 : 18,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.01),

                              // Subtítulo responsivo
                              Text(
                                "Welcome Back! We are happy to have \n you back".tr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              // Campo de telefone com largura limitada em tablets
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 400 : double.infinity,
                                ),
                                child: TextFormField(
                                  validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                                  keyboardType: TextInputType.number,
                                  textCapitalization: TextCapitalization.sentences,
                                  controller: controller.phoneNumberController.value,
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.poppins(
                                    color: themeChange.getThem() ? Colors.white : Colors.black,
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 16 : 12,
                                    ),
                                    prefixIcon: CountryCodePicker(
                                      onChanged: (value) {
                                        controller.countryCode.value = value.dialCode.toString();
                                      },
                                      showCountryOnly: true,
                                      dialogBackgroundColor: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
                                      initialSelection: controller.countryCode.value,
                                      comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                                      flagDecoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(2)),
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                    ),
                                    hintText: "Phone number".tr,
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              // Botão Next com largura limitada
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 400 : double.infinity,
                                ),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: "Next".tr,
                                  onPress: () {
                                    controller.sendCode();
                                  },
                                ),
                              ),

                              // Divisor OR com espaçamento responsivo
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: screenHeight * 0.05,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(height: 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        "OR".tr,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(height: 1),
                                    ),
                                  ],
                                ),
                              ),

                              // Botões de login social com largura limitada
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 400 : double.infinity,
                                ),
                                child: Column(
                                  children: [
                                    ButtonThem.buildBorderButton(
                                      context,
                                      title: "Login with google".tr,
                                      iconVisibility: true,
                                      iconAssetImage: 'assets/icons/ic_google.png',
                                      onPress: () async {
                                        ShowToastDialog.showLoader("Aguarde, por favor...".tr);
                                        await controller.signInWithGoogle().then((value) {
                                          ShowToastDialog.closeLoader();
                                          if (value != null) {
                                            if (value.additionalUserInfo!.isNewUser) {
                                              print("----->new user");
                                              UserModel userModel = UserModel();
                                              userModel.id = value.user!.uid;
                                              userModel.email = value.user!.email;
                                              userModel.fullName = value.user!.displayName;
                                              userModel.profilePic = value.user!.photoURL;
                                              userModel.loginType = Constant.googleLoginType;

                                              ShowToastDialog.closeLoader();
                                              Get.to(const InformationScreen(), arguments: {
                                                "userModel": userModel,
                                              });
                                            } else {
                                              print("----->old user");
                                              FireStoreUtils.userExitOrNot(value.user!.uid).then((userExit) async {
                                                ShowToastDialog.closeLoader();
                                                if (userExit == true) {
                                                  UserModel? userModel = await FireStoreUtils.getUserProfile(value.user!.uid);
                                                  if (userModel != null) {
                                                    if (userModel.isActive == true) {
                                                      Get.offAll(const DashBoardScreen());
                                                    } else {
                                                      await FirebaseAuth.instance.signOut();
                                                      ShowToastDialog.showToast("This user is disable please contact administrator".tr);
                                                    }
                                                  }
                                                } else {
                                                  UserModel userModel = UserModel();
                                                  userModel.id = value.user!.uid;
                                                  userModel.email = value.user!.email;
                                                  userModel.fullName = value.user!.displayName;
                                                  userModel.profilePic = value.user!.photoURL;
                                                  userModel.loginType = Constant.googleLoginType;

                                                  Get.to(const InformationScreen(), arguments: {
                                                    "userModel": userModel,
                                                  });
                                                }
                                              });
                                            }
                                          }
                                        });
                                      },
                                    ),

                                    SizedBox(height: screenHeight * 0.02),

                                    Visibility(
                                      visible: Platform.isIOS,
                                      child: ButtonThem.buildBorderButton(
                                        context,
                                        title: "Login with apple".tr,
                                        iconVisibility: true,
                                        iconAssetImage: 'assets/icons/ic_apple.png',
                                        onPress: () async {
                                          await controller.signInWithApple().then((value) {
                                            if (value.additionalUserInfo!.isNewUser) {
                                              log("----->new user");
                                              UserModel userModel = UserModel();
                                              userModel.id = value.user!.uid;
                                              userModel.email = value.user!.email;
                                              userModel.profilePic = value.user!.photoURL;
                                              userModel.loginType = Constant.appleLoginType;

                                              Get.to(const InformationScreen(), arguments: {
                                                "userModel": userModel,
                                              });
                                            } else {
                                              print("----->old user");
                                              FireStoreUtils.userExitOrNot(value.user!.uid).then((userExit) async {
                                                if (userExit == true) {
                                                  UserModel? userModel = await FireStoreUtils.getUserProfile(value.user!.uid);
                                                  if (userModel != null) {
                                                    if (userModel.isActive == true) {
                                                      Get.offAll(const DashBoardScreen());
                                                    } else {
                                                      await FirebaseAuth.instance.signOut();
                                                      ShowToastDialog.showToast("This user is disable please contact administrator".tr);
                                                    }
                                                  }
                                                } else {
                                                  UserModel userModel = UserModel();
                                                  userModel.id = value.user!.uid;
                                                  userModel.email = value.user!.email;
                                                  userModel.profilePic = value.user!.photoURL;
                                                  userModel.loginType = Constant.googleLoginType;

                                                  Get.to(const InformationScreen(), arguments: {
                                                    "userModel": userModel,
                                                  });
                                                }
                                              });
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),
                            ],
                          ),
                        ),
                      ),

                      // Termos e condições no bottom com padding responsivo
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? screenWidth * 0.1 : 20,
                          vertical: 25,
                        ),
                        child: Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 500 : double.infinity,
                            ),
                            child: Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                text: 'By tapping "Next" you agree to '.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 14 : 12,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(const TermsAndConditionScreen(
                                          type: "terms",
                                        ));
                                      },
                                    text: 'Terms and conditions'.tr,
                                    style: GoogleFonts.poppins(
                                      decoration: TextDecoration.underline,
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(const TermsAndConditionScreen(
                                          type: "privacy",
                                        ));
                                      },
                                    text: 'privacy policy'.tr,
                                    style: GoogleFonts.poppins(
                                      decoration: TextDecoration.underline,
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}