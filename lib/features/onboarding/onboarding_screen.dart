import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_error_alert.dart';

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
  const OnboardingScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(0);
        setState(() => _currentPage = 0);
        AppErrorAlert.show(context, widget.errorMessage!);
      });
    }
  }

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
            fit: BoxFit.contain,
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
  List<Widget> _geoIllustration(double w, double h) => [
        Positioned.fill(
          child: Image.asset(
            'assets/images/onboarding_2.jpg',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ];

  // Slide 2 — Verified breeders
  // Premium badge with association labels floating around it.
  List<Widget> _verifiedIllustration(double w, double h) => [
        Positioned.fill(
          child: Image.asset(
            'assets/images/onboarding_3.jpg',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ];
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
