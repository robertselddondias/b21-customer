import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/global_setting_conroller.dart';
import 'package:customer/firebase_options.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/themes/Styles.dart';
import 'package:customer/ui/splash_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/global_keyboard_dismiss.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'utils/Preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest, // Para iOS
  );

  final isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  ShowToastDialog.configureLoader(isDarkMode: isDarkMode);

  // Configura o Crashlytics para capturar erros automaticamente
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await Preferences.initPref();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    getCurrentAppTheme();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(builder: (context, value, child) {
        return GlobalKeyboardDismiss(
            child: GetMaterialApp(
                title: 'B-21',
                debugShowCheckedModeBanner: false,
                theme: Styles.themeData(
                    themeChangeProvider.darkTheme == 0
                        ? true
                        : themeChangeProvider.darkTheme == 1
                        ? false
                        : themeChangeProvider.getSystemThem(),
                    context),
                localizationsDelegates: const [
                  CountryLocalizations.delegate,
                ],
                locale: LocalizationService.locale,
                fallbackLocale: LocalizationService.locale,
                translations: LocalizationService(),
                builder: EasyLoading.init(),
                home: GetBuilder<GlobalSettingController>(
                    init: GlobalSettingController(),
                    builder: (context) {
                      return const SplashScreen();
                    }
                )
            )
        );
      }),
    );
  }
}
