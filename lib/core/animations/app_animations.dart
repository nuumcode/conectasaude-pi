// ═══════════════════════════════════════════════════════════════════
//  app_animations.dart  —  ConectaSaúdePI
//  Painters, widgets reutilizáveis e rotas de transição.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

// ── PAINTERS ────────────────────────────────────────────────────────

/// Anel externo sweep gradient (gira via controller externo)
class ArcRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawArc(
      Rect.fromLTWH(2, 2, s.width - 4, s.height - 4),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const SweepGradient(
          colors: [
            AppColors.blueLt,
            AppColors.greenLt,
            Colors.transparent
          ],
          stops: [0, 0.55, 1],
          startAngle: 0,
          endAngle: math.pi * 2,
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Anel interno sutil (gira ao contrário via controller externo)
class InnerRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawCircle(
      s.center(Offset.zero),
      s.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.blue.withOpacity(0.2),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Cruz com ECG — fallback do ícone quando asset não carrega
class CrossEcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()
      ..color = const Color(0xFF00B894)
      ..style = PaintingStyle.fill;
    final b = Paint()
      ..color = AppColors.primaryDeep
      ..style = PaintingStyle.fill;
    final e = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final w = s.width, h = s.height;
    const r = Radius.circular(10);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .30, h * .41, w * .48, h * .22), r),
        g);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .41, h * .30, w * .22, h * .48), r),
        g);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .20, h * .36, w * .50, h * .22), r),
        b);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .36, h * .20, w * .22, h * .50), r),
        b);

    final pts = [
      Offset(w * .22, h * .48),
      Offset(w * .33, h * .48),
      Offset(w * .37, h * .39),
      Offset(w * .41, h * .57),
      Offset(w * .46, h * .31),
      Offset(w * .50, h * .50),
      Offset(w * .55, h * .48),
      Offset(w * .65, h * .48),
      Offset(w * .70, h * .40),
      Offset(w * .74, h * .55),
      Offset(w * .79, h * .48),
      Offset(w * .85, h * .48),
    ];
    canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..addPolygon(pts, false),
        e);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Círculo com ECG — deco canto inferior direito (canvas 100×100)
class CircleEcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * .46;

    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF4CA3FF));
    canvas.drawCircle(
        c,
        r * .62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = const Color(0xFF00D4AA));

    final xL = c.dx - r * .84, xR = c.dx + r * .84, span = xR - xL, ey = c.dy;
    final pts = [
      Offset(xL, ey),
      Offset(xL + span * .22, ey),
      Offset(xL + span * .30, ey - s.height * .11),
      Offset(xL + span * .37, ey + s.height * .15),
      Offset(xL + span * .46, ey - s.height * .25),
      Offset(xL + span * .54, ey + s.height * .07),
      Offset(xL + span * .62, ey),
      Offset(xR, ey),
    ];
    canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..addPolygon(pts, false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF00D4AA));
    canvas.drawCircle(Offset(xL + span * .46, ey - s.height * .25), 2.2,
        Paint()..color = const Color(0xFF00D4AA));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Arco aberto — deco canto inferior esquerdo (canvas 90×90)
class ArcDecoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: s.width * .44),
        math.pi * .6,
        math.pi * 1.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF4CA3FF));
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: s.width * .28),
        math.pi * .8,
        math.pi * .9,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF00D4AA));
    canvas.drawCircle(c, 2.0, Paint()..color = const Color(0xFF4CA3FF));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Cruzes decorativas nos cantos
class CornerCrossesPainter extends CustomPainter {
  void _cross(
      Canvas c, Paint p, double cx, double cy, double arm, double thick) {
    final rr = Radius.circular(thick / 2);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy), width: thick, height: arm * 2),
            rr),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy), width: arm * 2, height: thick),
            rr),
        p);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final pb = Paint()..color = const Color(0xFF4CA3FF);
    final pg = Paint()..color = const Color(0xFF00D4AA);
    _cross(canvas, pb, s.width - 44, 60, 14, 7);
    _cross(canvas, pb, s.width - 22, 104, 9, 4);
    _cross(canvas, pg, 34, s.height - 88, 14, 7);
    _cross(canvas, pb, s.width - 60, s.height - 110, 10, 4);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Grade de pontos sutis
class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (double x = 40; x < s.width; x += 40)
      for (double y = 40; y < s.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Logo Google — 4 arcos coloridos
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * .72),
        (i * math.pi / 2) - math.pi / 4,
        math.pi / 2 - 0.1,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * .7, cy),
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── WIDGETS REUTILIZÁVEIS ────────────────────────────────────────────

/// Fundo compartilhado — usado na LoginCidadaoScreen
/// (AuthWrapper constrói o fundo manualmente para animar a interpolação)
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.4,
          colors: [AppColors.bgMid, AppColors.navyDeep],
        ),
      ),
      child: Stack(children: [
        Positioned(
            top: -sz.height * .12,
            right: -sz.width * .18,
            child: AppOrb(size: 320, color: AppColors.blue.withOpacity(.13))),
        Positioned(
            top: sz.height * .06,
            left: -sz.width * .10,
            child: AppOrb(size: 200, color: AppColors.blueLt.withOpacity(.09))),
        Positioned(
            bottom: -sz.height * .08,
            left: -sz.width * .14,
            child:
                AppOrb(size: 260, color: AppColors.greenLt.withOpacity(.09))),
        Positioned(
            bottom: 32,
            right: 18,
            child: Opacity(
                opacity: .09,
                child: CustomPaint(
                    size: const Size(100, 100), painter: CircleEcgPainter()))),
        Positioned(
            bottom: 64,
            left: -22,
            child: Opacity(
                opacity: .07,
                child: CustomPaint(
                    size: const Size(90, 90), painter: ArcDecoPainter()))),
        Positioned.fill(
            child: Opacity(
                opacity: .07,
                child: CustomPaint(painter: CornerCrossesPainter()))),
        Positioned.fill(
            child: Opacity(
                opacity: .025, child: CustomPaint(painter: DotGridPainter()))),
        child,
      ]),
    );
  }
}

/// Linha gradiente no topo
/// IMPORTANTE: retorna Container puro — sem Positioned interno.
/// O pai deve envolver com Positioned(top:0, left:0, right:0).
class AppTopLine extends StatelessWidget {
  const AppTopLine({super.key});
  @override
  Widget build(BuildContext context) => Container(
        height: 2,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.blue,
              AppColors.greenLt,
              Colors.transparent,
            ],
            stops: [0, 0.3, 0.7, 1],
          ),
        ),
      );
}

/// Orb (bola de luz difusa) reutilizável
class AppOrb extends StatelessWidget {
  final double size;
  final Color color;
  const AppOrb({super.key, required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

/// Footer do splash — retorna Column puro (sem Positioned interno).
/// O pai deve envolver com Positioned(bottom:24, left:0, right:0).
class AppSplashFooter extends StatelessWidget {
  final String label;
  final String version;
  const AppSplashFooter({
    super.key,
    this.label = 'CETI Luis Teixeira  •  DO PIAUÍ PARA O MUNDO 2026',
    this.version = 'v1.0.0  •  MVP HACKATHON',
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blueLt.withOpacity(.18)),
              color: const Color(0xFF0D2B5C).withOpacity(.55),
            ),
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(.30),
                    letterSpacing: 1.4)),
          ),
          const SizedBox(height: 6),
          Text(version,
              style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 8,
                  color: Color(0x28FFFFFF),
                  letterSpacing: 2)),
        ],
      );
}

// ── TRANSIÇÕES DE ROTA ───────────────────────────────────────────────

/// Fade + scale suave (uso geral)
class AppFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  AppFadeRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            final fade =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            final scale = Tween(begin: 0.97, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
            return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child));
          },
        );
}

/// Transição Hero-aware: AuthWrapper → LoginCidadaoScreen
///
/// • Fade in da Login com easeOutCubic puro (SEM Interval — evita crash)
/// • Slide up ultrasutil (+3% → 0)
/// • Hero 'brand-logo' voa automaticamente (Flutter gerencia)
class AppHeroFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppHeroFadeRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            // SEM Interval — Interval com end > 1.0 causa crash em curves.dart:180
            final fade = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic, // suave do início ao fim
            );
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}
