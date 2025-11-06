import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/languages.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/local_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void shareApp() {
    const packageName = "com.selfcare.stressrelief.anxietyrelief";
    const appUrl = "https://play.google.com/store/apps/details?id=$packageName";

    Share.share(
      "Hey! Check out this amazing Stress Relief & Anxiety Relief app:\n$appUrl",
      subject: "Stress Relief & Anxiety Relief App",
    );
  }

  // Function to open privacy policy
  Future<void> openPrivacyPolicy() async {
    const url = "https://sites.google.com/view/pdfreaderedito/home";
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final lc = Get.find<LocaleController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    lc.t('settings'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(height: size.height * 0.03),
                  _buildSettingsTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: lc.t('privacyPolicy'),
                    onTap: openPrivacyPolicy
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.star_border_outlined,
                    title: lc.t('rateUs'),
                    onTap: () {
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.share_outlined,
                    title: lc.t('shareApp'),
                    onTap: shareApp
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.language_outlined,
                    title: lc.t('languages'),
                    onTap: () {
                      Get.to(() => SelectLanguageScreen());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary,
          borderRadius: BorderRadius.circular(16),

        ),
        child: ListTile(
          leading: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: colorScheme.primary,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
