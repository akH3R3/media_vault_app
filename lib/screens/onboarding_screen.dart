import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:media_vault/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  final PageController _controller = PageController();
  bool onLastPage = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 1);
              });
            },
            children: [
              Container(
                color: Colors.pinkAccent,
                child: Lottie.network(
                  'https://lottie.host/c2e9291f-920f-409d-89a5-c84042b5099f/Kx7timZh6B.json',
                ),
              ),
              Container(
                color: Colors.yellow,
                child: Lottie.network(
                  'https://lottie.host/b57444f9-4f3a-49e3-b5ca-316a53ab6cd1/cxmCRVrPqU.json',
                ),
              ),
            ],
          ),
          Container(
              alignment: const Alignment(0, 0.80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      // onTap: () {
                      //   _controller.nextPage(
                      //       duration: const Duration(microseconds: 500),
                      //       curve: Curves.easeIn);
                      // },
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('seenOnboarding', true);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return const SplashScreen();
                            }));
                      },
                      child: const Text("Skip")),
                  SmoothPageIndicator(controller: _controller, count: 2),
                  onLastPage
                      ? GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('seenOnboarding', true);
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return const SplashScreen();
                            }));
                          },
                          child: const Text("Done"))
                      : GestureDetector(
                          onTap: () {
                            _controller.nextPage(
                                duration: const Duration(microseconds: 500),
                                curve: Curves.easeIn);
                          },
                          child: const Text("Next")),
                ],
              )),
        ],
      ),
    );
  }
}
