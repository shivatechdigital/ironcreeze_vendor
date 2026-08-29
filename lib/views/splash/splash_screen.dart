import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../core/enums/vendor_status.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNext();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  void _navigateToNext() {
    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final vendorProvider = Provider.of<VendorProvider>(
        context,
        listen: false,
      );

      while (authProvider.status == AuthStatus.loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      if (authProvider.user != null) {
        final vendorExists = await vendorProvider.checkVendorExists(
          authProvider.user!.uid,
        );

        if (vendorExists) {
          await vendorProvider.fetchVendor(authProvider.user!.uid);

          if (!mounted) return;

          if (vendorProvider.vendorStatus == VendorStatus.approved) {
            AppRoutes.navigateAndClearStack(context, AppRoutes.mainNavigation);
          } else {
            AppRoutes.navigateAndClearStack(context, AppRoutes.pendingApproval);
          }
        } else {
          AppRoutes.navigateAndClearStack(
            context,
            AppRoutes.vendorDetails,
            arguments: {
              'email': authProvider.user!.email,
              'phone': authProvider.user!.phoneNumber,
              'authType': authProvider.authType?.value,
            },
          );
        }
      } else {
        AppRoutes.navigateAndClearStack(context, AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EB), // warm cream background
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo image ──────────────────────────────────
                    Image.asset(
                      'assets/logo.png',
                      width: 160,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 12),

                    // ── "Partner" text ───────────────────────────────
                    const Text(
                      'Partner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA6A02),
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Loading indicator ────────────────────────────
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFEA6A02),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
