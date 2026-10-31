import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DogoLogo extends StatelessWidget {
  final double size;

  const DogoLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'D',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DOGO',
                style: GoogleFonts.sora(
                  fontSize: size * 0.48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CREW',
                style: GoogleFonts.manrope(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppColors.gold,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
