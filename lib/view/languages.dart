import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/widgets/bottom_navigation_bar.dart';

import '../contents/services/app_start_service.dart';
import '../controller/local_controller.dart';
import 'home.dart';
import 'homeview.dart';
import 'onboarding.dart';

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  final TextEditingController _searchController = TextEditingController();

  // list of available languages by code + flag
  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'flag': '🇺🇸'},
    {'code': 'ar', 'flag': '🇸🇦'},
    {'code': 'zh', 'flag': '🇨🇳'},
    {'code': 'de', 'flag': '🇩🇪'},
    {'code': 'fr', 'flag': '🇫🇷'},
    {'code': 'id', 'flag': '🇮🇩'},
    {'code': 'ja', 'flag': '🇯🇵'},
    {'code': 'pt', 'flag': '🇵🇹'},
    {'code': 'ru', 'flag': '🇷🇺'},
    {'code': 'tr', 'flag': '🇹🇷'},
  ];

  final LocaleController _localeController = Get.put(LocaleController());

  // filtered list of codes based on the translated display name
  late RxList<Map<String, String>> _filtered;

  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _filtered = RxList.from(_languages);
    _searchController.addListener(_onSearchChanged);

    // Set initially selected code from current locale
    _selectedCode = _localeController.current.value;

    // whenever the locale changes we need to re-run search to update displayed names
    ever(
      _localeController.current,
          (_) => _applySearch(_searchController.text),
    );
  }

  void _onSearchChanged() => _applySearch(_searchController.text);

  void _applySearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered.value = List<Map<String, String>>.from(_languages);
      return;
    }

    final results = _languages.where((lang) {
      final display = _localeController
          .getLanguageName(lang['code']!)
          .toLowerCase();
      return display.contains(q) || lang['code']!.contains(q);
    }).toList();

    _filtered.value = results;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSelect(String code) {
    setState(() => _selectedCode = code);
    // change app language immediately
    _localeController.changeLocale(code);
    // if using GetMaterialApp and want system localization widgets to change, call:
    // Get.updateLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Obx(() {
                final lc = _localeController;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lc.t('select_language'),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge,
                        ),
                        ElevatedButton(
                          onPressed: _selectedCode == null
                              ? null
                              : () async {
                            await _localeController.changeLocale(_selectedCode!);

                            final isFirstTime = await AppStartService.isFirstLaunch();
                            if (isFirstTime) {
                              await AppStartService.setLaunched();
                              Get.off(()=>Onboarding());
                            } else {
                              Get.back(); // if from settings
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          ),
                          child: Text(
                            _localeController.t('next'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      style: Theme.of(context).textTheme.titleSmall,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        hintText: lc.t('search_language'),
                        hintStyle: Theme.of(context).textTheme.titleSmall,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSecondary,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      lc.t('all_languages'),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Language List
                    Expanded(
                      child: Obx(() {
                        return ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final lang = _filtered[index];
                            final code = lang['code']!;
                            final isSelected = _selectedCode == code;
                            final displayName = lc.getLanguageName(code);

                            return GestureDetector(
                              onTap: () => _onSelect(code),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          lang['flag']!,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? Theme.of(
                                          context,
                                        ).colorScheme.primary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ?  Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Theme.of(context).colorScheme.onSecondary,
                                      )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

    );
  }
}
