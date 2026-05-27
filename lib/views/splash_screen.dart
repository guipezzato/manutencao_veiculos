import 'package:flutter/material.dart';
import 'package:manutencao_veiculos/main.dart';
import '../app_theme/app_theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(), 
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Controle de Manutenção',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu veículo em boas mãos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
