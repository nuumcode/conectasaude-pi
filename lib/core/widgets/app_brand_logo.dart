// ═══════════════════════════════════════════════════════════════════
//  app_brand_logo.dart  —  ConectaSaúdePI
//  Widget de logo padronizado para transições Hero perfeitas.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../animations/app_animations.dart';

class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double textOpacity;
  final bool isHero;
  final String heroTag;
  final CrossAxisAlignment crossAxisAlignment;

  const AppBrandLogo({
    super.key,
    this.size = 86,
    this.showText = true,
    this.textOpacity = 1.0,
    this.isHero = true,
    this.heroTag = 'brand-logo',
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        _buildIcon(),
        if (showText) ...[
          const SizedBox(height: 16),
          Opacity(
            opacity: textOpacity,
            child: _buildBrandName(),
          ),
        ],
      ],
    );

    if (isHero) {
      return Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: logoBody,
        ),
      );
    }

    return logoBody;
  }

  Widget _buildIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B6B), AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.35),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.05),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          'assets/logo-var01.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          frameBuilder: (ctx, child, frame, wasSyncLoaded) {
            if (wasSyncLoaded || frame != null) {
              return Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: child,
              );
            }
            return Container(color: const Color(0xFF0D2B6B));
          },
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF0D2B6B),
            child: CustomPaint(painter: CrossEcgPainter()),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandName() {
    final isCenter = crossAxisAlignment == CrossAxisAlignment.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        RichText(
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
          text: TextSpan(children: [
            const TextSpan(
              text: 'Conecta',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            TextSpan(
              text: 'Saúde',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.blueLt,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                    color: AppColors.blueLt.withOpacity(0.4),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
            TextSpan(
              text: 'PI',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.greenLt,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                    color: AppColors.greenLt.withOpacity(0.5),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Text(
          'SUA SAÚDE CONECTADA.',
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.28),
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}
