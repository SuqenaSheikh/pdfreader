import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/splash.dart';
import 'contents/themes/apptheme.dart';
import 'controller/local_controller.dart';


Future<void> main() async {
  final localeController = Get.put(LocaleController());
  await localeController.loadSavedLanguage();
  runApp(PDFReaderApp(localeController: localeController,));
}

class PDFReaderApp extends StatelessWidget {
  final LocaleController localeController;

  const PDFReaderApp({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    final lc = Get.find<LocaleController>();
    return Obx((){
      final langCode = localeController.current.value;
      final isRtl = localeController.isRtl;
      return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,

          child: GetMaterialApp(
            title: 'PDF Reader',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: SplashScreen(),
            locale: Locale(langCode),

          ),);
    }

    );
  }
}


