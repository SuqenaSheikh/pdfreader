import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/homeview.dart';
import 'package:pdfread/view/widgets/bottom_navigation_bar.dart';
import '../contents/assets/assets.dart';
import '../contents/services/app_start_service.dart';
import 'home.dart';
import 'languages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Create smooth left-to-right loading animation (3 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Navigate after animation completes
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        //Get.off(() => SelectLanguageScreen());
        final isFirstTime = await AppStartService.isFirstLaunch();

        if (isFirstTime) {
          Get.offAll(()=>SelectLanguageScreen());
        } else {
          Get.offAll(()=>BottomBar());
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          ///Icon
          Image.asset('assets/images/Icon.png', height: 150, width: 150,),

          const SizedBox(height: 32),

          ///Text
          Text('PDF Reader', style: Theme.of(context).textTheme.headlineLarge),

          ///Space
          const Spacer(),

          /// Loading
           Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          /// Red progress bar that fills left to right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _animation.value,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .5),
                    minHeight: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
