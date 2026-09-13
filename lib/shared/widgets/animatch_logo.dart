import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class AnimatchLogo extends StatelessWidget {
  const AnimatchLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/animatch_icon.png',
          width: size,
          height: size,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Animatch',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.merriweather(
              fontSize: size,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
