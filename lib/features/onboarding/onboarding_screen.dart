import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Slide {
  const _Slide({
    required this.headline,
    required this.subheadline,
    required this.topColor,
    required this.bottomColor,
  });

  final String headline;
  final String subheadline;
  final Color topColor;
  final Color bottomColor;
}

const _slides = [
  _Slide(
    headline: 'Conecte seus animais\ncom a melhor genética\ndo Brasil.',
    subheadline:
        'Encontre parceiros de reprodução por raça, região e qualidade genética.',
    topColor: Colors.white,
    bottomColor: Colors.white,
  ),
  _Slide(
    headline: 'Genética de elite,\na distância certa.',
    subheadline:
        'Veja animais disponíveis perto de você e reduza os custos de transporte.',
    topColor: Color(0xFF0D2105),
    bottomColor: Color(0xFF2D5016),
  ),
  _Slide(
    headline: 'Criadores verificados,\nnegociações confiáveis.',
    subheadline:
        'Criadores validados pela ABCZ, ABQM e demais associações de raça.',
    topColor: Color(0xFF3D2A00),
    bottomColor: Color(0xFFC8860A),
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  // TODO: write Hive 'hasSeenOnboarding' flag before navigating
  void _finish() => context.push(AppRoutes.register);
  void _goToLogin() => context.push(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Slide 0 has a white background — use dark status bar icons there
    final onDark = _currentPage != 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: onDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: slide.topColor,
        body: Column(
          children: [
            // ── Image region — fills all space above the content panel ─────
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (_, i) =>
                        _SlideBackground(slide: _slides[i], index: i),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                onDark ? Colors.white70 : AppColors.muted,
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: const Text('Pular'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content panel ──────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(28, 20, 28, 12 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 160,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      ),
                      child: _SlideText(
                        key: ValueKey(_currentPage),
                        slide: slide,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DotsIndicator(
                    count: _slides.length,
                    current: _currentPage,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Começar' : 'Continuar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Já tenho conta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide background — per-slide illustration
// ---------------------------------------------------------------------------

class _SlideBackground extends StatelessWidget {
  const _SlideBackground({required this.slide, required this.index});

  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [slide.topColor, slide.bottomColor],
        ),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: switch (index) {
              0 => _matchingIllustration(w, h),
              1 => _geoIllustration(w, h),
              _ => _verifiedIllustration(w, h),
            },
          );
        },
      ),
    );
  }

  // Slide 0 — Matching concept
  // Square image (horse + bull + DNA helix) — cover fills the portrait area.
  List<Widget> _matchingIllustration(double w, double h) => [
        Positioned.fill(
          child: Image.asset(
            'assets/images/onboarding_1.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        // Light top scrim so the Skip button stays readable over the pale background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: h * 0.22,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Colors.transparent],
              ),
            ),
          ),
        ),
      ];

  // Slide 1 — Geo-proximity
  // Radar rings from centre, a pin, and livestock icons at different distances.
  List<Widget> _geoIllustration(double w, double h) => [
        // Radar rings
        Center(child: _ring(w * 0.95, Colors.white.withValues(alpha: 0.05))),
        Center(child: _ring(w * 0.65, Colors.white.withValues(alpha: 0.09))),
        Center(child: _ring(w * 0.35, Colors.white.withValues(alpha: 0.14))),
        // Scattered animals at ring positions
        Positioned(
          left: w * 0.07,
          top: h * 0.18,
          child: Icon(Icons.agriculture,
              size: 34, color: Colors.white.withValues(alpha: 0.55)),
        ),
        Positioned(
          right: w * 0.08,
          top: h * 0.32,
          child: Icon(Icons.agriculture,
              size: 28, color: Colors.white.withValues(alpha: 0.45)),
        ),
        Positioned(
          left: w * 0.18,
          bottom: h * 0.22,
          child: Icon(Icons.agriculture,
              size: 24, color: Colors.white.withValues(alpha: 0.38)),
        ),
        Positioned(
          right: w * 0.2,
          bottom: h * 0.32,
          child: Icon(Icons.agriculture,
              size: 22, color: Colors.white.withValues(alpha: 0.32)),
        ),
        // Central pin
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 80,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
      ];

  // Slide 2 — Verified breeders
  // Premium badge with association labels floating around it.
  List<Widget> _verifiedIllustration(double w, double h) => [
        // Outer decorative ring
        Center(
          child: Container(
            width: w * 0.6,
            height: w * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
            ),
          ),
        ),
        // Inner glow circle
        Center(
          child: Container(
            width: w * 0.38,
            height: w * 0.38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // Central badge icon
        Center(
          child: Icon(
            Icons.workspace_premium,
            size: 96,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        // Association labels
        Positioned(
          left: w * 0.06,
          top: h * 0.16,
          child: _assocTag('ABCZ'),
        ),
        Positioned(
          right: w * 0.06,
          top: h * 0.28,
          child: _assocTag('ABQM'),
        ),
        Positioned(
          left: w * 0.1,
          bottom: h * 0.22,
          child: _assocTag('ABCAngus'),
        ),
        Positioned(
          right: w * 0.08,
          bottom: h * 0.3,
          child: _assocTag('ABCCMM'),
        ),
      ];

  // ── Helpers ──────────────────────────────────────────────────────────────


  Widget _ring(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
      );

  Widget _assocTag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SlideText extends StatelessWidget {
  const _SlideText({super.key, required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slide.headline, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          slide.subheadline,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.muted, height: 1.55),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
