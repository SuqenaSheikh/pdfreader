import 'dart:ui';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../contents/localization/app_strings.dart';

class LocaleController extends GetxController {
  final RxString current = 'en'.obs;
  static const String _langKey = 'selected_language';

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey);
    if (savedLang != null && AppStrings.localized.containsKey(savedLang)) {
      current.value = savedLang;
      Get.updateLocale(Locale(savedLang));
    }
  }

  Future<void> changeLocale(String langCode) async {
    current.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
    Get.updateLocale(Locale(langCode));
  }

  String t(String key) {
    final map = AppStrings.localized[current.value];
    return map?[key] ?? key;
  }

  String getLanguageName(String targetLangCode) {
    final key = 'lang_$targetLangCode';
    return t(key);
  }

  bool get isRtl => ['ar', 'ur', 'fa', 'he'].contains(current.value);
}
