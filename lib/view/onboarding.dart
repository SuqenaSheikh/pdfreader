import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfread/view/homeview.dart';
import 'package:pdfread/view/widgets/bottom_navigation_bar.dart';

import '../contents/model/onboarding_model.dart';
import '../contents/themes/app_colors.dart';
import '../controller/local_controller.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final LocaleController lc = Get.find<LocaleController>();


  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Read Anytime, Anywhere',
      description: 'Access and read your favorite PDFs on the go with a smooth and intuitive experience.',
      imagePath: 'assets/images/onboard1.png',
    ),
    OnboardingData(
      title: 'Edit PDFs Instantly',
      description: 'Modify text, images, and pages in your PDF files with just a few taps — no extra tools needed.',
      imagePath: 'assets/images/onboard2.png',
    ),
    OnboardingData(
      title: 'Sign & Share Securely',
      description: 'Add your digital signature and share documents safely with built-in privacy protection.',
      imagePath: 'assets/images/onboard3.png',
    ),
  ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to your home or main screen here
      Get.offAll(()=>BottomBar());
      // AnalyticsService.logEvent(
      //   "Get Off to mood analyzer screen",
      // );

    }
  }

  @override
  Widget build(BuildContext context) {
    double size= MediaQuery.of(context).size.height;
    return Obx((){
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Skip button
                if (_currentPage != _pages.length - 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, right: 20),
                      child: TextButton(
                        onPressed: () {
                          _pageController.jumpToPage(_pages.length - 1);
                          // AnalyticsService.logEvent(
                          //   "Pressed Skip on onboarding screen",
                          // );
                        },
                        child: Text(
                          lc.t('skip'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ),

                // PageView with images
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                            }
                            return Center(
                              child: Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: Image.asset(
                                    _pages[index].imagePath,
                                    width: 300,
                                    height: 350,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Bottom content card
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Page indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _pages.length,
                                    (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin:
                                  const EdgeInsets.symmetric(horizontal: 5),
                                  width: _currentPage == index ? 40 : 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index
                                        ? AppColors.primaryColor
                                        : AppColors.primaryColor.withAlpha(50),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Title
                            SizedBox(
                              height: size/13,

                              child: Text(
                                lc.t('${_pages[_currentPage].title}'),
                                style:  Theme.of(context).textTheme.headlineLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),


                            // Description
                            SizedBox(
                              height: size/13,
                              child: Center(
                                child: Text(
                                  lc.t('${_pages[_currentPage].description}'),
                                  textAlign: TextAlign.center,
                                  style:  Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Continue button
                            // Continue / Done button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 17),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _goToNextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.zero, // 🔥 remove default padding
                                    alignment: Alignment.center, // 🔥 ensures text stays centered
                                  ),
                                  child: Text(
                                    lc.t(_currentPage == _pages.length - 1 ? "done" : "continue"),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white, height: 1), // 🔥 perfectly center text
                                  ),
                                ),
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
        );

    });
  }
}
