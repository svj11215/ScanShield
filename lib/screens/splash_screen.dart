import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation Intervals (Total: 2200ms)
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressBarWidth;

  bool _imageLoadFailed = false;

  @override
  void initState() {
    super.initState();

    // Trigger non-blocking backend warm-up immediately on app start
    ApiService().warmUpBackend();

    // 1. Initialize Single AnimationController for exactly 2200ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 2. Define Animation Sequences using Curves and Intervals
    
    // 0ms-800ms: Logo scales 0.6 -> 1.0 with Curves.easeOutBack & fades in
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.36, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.36, curve: Curves.easeOutBack),
      ),
    );

    // 800ms-1400ms: App name fades in + slides up 15px
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.64, curve: Curves.easeIn),
    );
    _titleSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.64, curve: Curves.easeOut),
      ),
    );

    // 1000ms-1600ms: Tagline fades in below
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.73, curve: Curves.easeIn),
    );

    // 1600ms-2200ms: Thin progress line animates left-to-right
    _progressBarWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeInOut),
      ),
    );

    // 3. Precache logo image to prevent initial flash/flicker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/logo.png'), context).catchError((_) {
        if (mounted) {
          setState(() {
            _imageLoadFailed = true;
          });
        }
      });
    });

    // 4. Start the animation and trigger navigation upon completion
    _controller.forward().then((_) => _checkAuthAndNavigate());
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    Widget destination;
    try {
      final user = FirebaseAuth.instance.currentUser;
      destination = user != null ? const HomeScreen() : const LoginScreen();
    } catch (e) {
      // Fallback to LoginScreen on any Firebase exceptions
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Central Content Area
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with subtle shadow
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Subtle brand glow behind logo
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha((25 * _logoOpacity.value).toInt()),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: AppColors.secondary.withAlpha((15 * _logoOpacity.value).toInt()),
                                    blurRadius: 60,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            // Scaling & Fading Logo
                            Transform.scale(
                              scale: _logoScale.value,
                              child: FadeTransition(
                                opacity: _logoOpacity,
                                child: SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: _imageLoadFailed
                                      ? Icon(
                                          Icons.shield_rounded,
                                          color: AppColors.primary,
                                          size: 100,
                                        )
                                      : Image.asset(
                                          'assets/images/logo.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.shield_rounded,
                                              color: AppColors.primary,
                                              size: 100,
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                // App Name
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: Text(
                          'ScanShield',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Tagline
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'Your Shield Against Malicious Apps',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Progress Indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: 0.35,
                    child: Container(
                      height: 3,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: _progressBarWidth.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
