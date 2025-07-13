import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/credit_card_screen/credit_card_save_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GetX<DashBoardController>(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            appBar: buildAppBar(context, controller, isTablet),
            drawer: buildAppDrawer(context, controller, isTablet),
            body: WillPopScope(
              onWillPop: controller.onWillPop,
              child: controller.getDrawerItemWidget(controller.selectedDrawerIndex.value),
            ),
          );
        });
  }

  PreferredSizeWidget buildAppBar(BuildContext context, DashBoardController controller, bool isTablet) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: isTablet ? 2 : 0,
      title: controller.selectedDrawerIndex.value != 0 && controller.selectedDrawerIndex.value != 6
          ? Text(
        controller.drawerItems[controller.selectedDrawerIndex.value].title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 20 : 18,
          fontWeight: FontWeight.w500,
        ),
      )
          : const Text(""),
      leading: Builder(builder: (context) {
        return InkWell(
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: SvgPicture.asset(
              'assets/icons/ic_humber.svg',
              width: isTablet ? 28 : 24,
              height: isTablet ? 28 : 24,
            ),
          ),
        );
      }),
      actions: [
        buildAppBarActions(context, controller, isTablet),
      ],
    );
  }

  Widget buildAppBarActions(BuildContext context, DashBoardController controller, bool isTablet) {
    if (controller.selectedDrawerIndex.value == 0) {
      return buildProfileAction(context, controller, isTablet);
    } else if (controller.selectedDrawerIndex.value == 3) {
      return buildAddCardAction(context, isTablet);
    }
    return Container();
  }

  Widget buildProfileAction(BuildContext context, DashBoardController controller, bool isTablet) {
    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: SizedBox(
                width: isTablet ? 28 : 24,
                height: isTablet ? 28 : 24,
                child: Constant.loader(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              );
            } else {
              UserModel driverModel = snapshot.data!;
              return InkWell(
                onTap: () {
                  controller.selectedDrawerIndex(7);
                },
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  child: ClipOval(
                    child: SizedBox(
                      width: isTablet ? 40 : 32,
                      height: isTablet ? 40 : 32,
                      child: CachedNetworkImage(
                        imageUrl: driverModel.profilePic.toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Constant.loader(),
                        errorWidget: (context, url, error) =>
                            Image.network(Constant.userPlaceHolder),
                      ),
                    ),
                  ),
                ),
              );
            }
          default:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Text(
                'Error'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            );
        }
      },
    );
  }

  Widget buildAddCardAction(BuildContext context, bool isTablet) {
    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: SizedBox(
                width: isTablet ? 28 : 24,
                height: isTablet ? 28 : 24,
                child: Constant.loader(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              );
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      splashColor: Colors.green.shade800,
                      onTap: () {
                        Get.to(() => CreditCardSaveScreen());
                      },
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 14 : 12),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          default:
            return Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Text(
                'Error'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            );
        }
      },
    );
  }

  Widget buildAppDrawer(BuildContext context, DashBoardController controller, bool isTablet) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = isTablet ? screenWidth * 0.4 : screenWidth * 0.85;

    var drawerOptions = <Widget>[];
    for (var i = 0; i < controller.drawerItems.length; i++) {
      var d = controller.drawerItems[i];
      drawerOptions.add(
        InkWell(
          onTap: () {
            controller.onSelectItem(i);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 8 : 6,
              vertical: isTablet ? 4 : 2,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: i == controller.selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 14 : 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    d.icon,
                    width: isTablet ? 22 : 18,
                    height: isTablet ? 22 : 18,
                    color: i == controller.selectedDrawerIndex.value
                        ? themeChange.getThem()
                        ? Colors.black
                        : Colors.white
                        : themeChange.getThem()
                        ? Colors.white
                        : AppColors.drawerIcon,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      d.title,
                      style: GoogleFonts.poppins(
                        color: i == controller.selectedDrawerIndex.value
                            ? themeChange.getThem()
                            ? Colors.black
                            : Colors.white
                            : themeChange.getThem()
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: isTablet ? 15 : 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          children: [
            buildDrawerHeader(context, isTablet),
            Column(children: drawerOptions),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerHeader(BuildContext context, bool isTablet) {
    return DrawerHeader(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: FutureBuilder<UserModel?>(
        future: FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: Constant.loader());
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                );
              } else {
                UserModel driverModel = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isTablet ? 40 : 30),
                      child: SizedBox(
                        height: isTablet ? 80 : Responsive.width(20, context),
                        width: isTablet ? 80 : Responsive.width(20, context),
                        child: CachedNetworkImage(
                          imageUrl: driverModel.profilePic.toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Constant.loader(),
                          errorWidget: (context, url, error) =>
                              Image.network(Constant.userPlaceHolder),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 10),
                    Flexible(
                      child: Text(
                        driverModel.fullName.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 18 : 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 2),
                    Flexible(
                      child: Text(
                        driverModel.email.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                );
              }
            default:
              return Center(
                child: Text(
                  'Error'.tr,
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              );
          }
        },
      ),
    );
  }
}