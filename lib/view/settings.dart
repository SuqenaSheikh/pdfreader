import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/languages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(

      body: SafeArea(
        child: Padding(
          padding:EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
             Expanded(
                 child: Column(
               children: [
                 SizedBox(height: size.height * 0.05),
                 _buildSettingsTile(
                   context,
                   icon: Icons.privacy_tip_outlined,
                   title: 'Privacy Policy',
                   onTap: () {
                     Get.toNamed('/privacy');
                   },
                 ),
                 _buildSettingsTile(
                   context,
                   icon: Icons.star_border_outlined,
                   title: 'Rate Us',
                   onTap: () {
                     // Handle play store or app store redirection
                   },
                 ),
                 _buildSettingsTile(
                   context,
                   icon: Icons.share_outlined,
                   title: 'Share App',
                   onTap: () {
                     // Handle app sharing
                   },
                 ),
                 _buildSettingsTile(
                   context,
                   icon: Icons.language_outlined,
                   title: 'Language',
                   onTap: () {
                     Get.to(()=>SelectLanguageScreen());
                   },
                 ),
               ],
             ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.primary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
