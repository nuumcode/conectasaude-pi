// ═══════════════════════════════════════════════════════════════════
//  auth_wrapper.dart  —  ConectaSaúdePI
//  (versão otimizada — logo surge sem placeholder)
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import 'login_cidadao_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with TickerProviderStateMixin {
  static const _labels = [
    'CONECTANDO UNIDADES...',
    'CARREGANDO ESCALAS...',
    'SINCRONIZANDO FILAS...',
    'PREPARANDO PAINEL...',
    'QUASE PRONTO...',
  ];
  int _step = 0;
  Timer? _stepTimer;
  bool _phaseB = false;

  // Controllers
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat(reverse: true);

  late final AnimationController _ringCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  late final AnimationController _progressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
    value: 0.06,
  )..forward();

  late final AnimationController _bgFadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final AnimationController _barCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1.0,
  );

  late final _float = Tween(begin: 0.0, end: -7.0)
      .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

  late final _pulse = Tween(begin: 0.35, end: 1.0)
      .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  late final _bgFade =
      CurvedAnimation(parent: _bgFadeCtrl, curve: Curves.easeInOut);
  late final _barFade =
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeOut);

  // Controlador para animar o surgimento da logo
  late final AnimationController _logoAppearCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 0.0,
  );

  @override
  void initState() {
    super.initState();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1600), (t) {
      if (!mounted) return;
      if (_step < _labels.length - 1) setState(() => _step++);
    });

    Future.delayed(const Duration(milliseconds: 1500), _enterPhaseB);
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pré-carrega a imagem para que esteja em cache antes da primeira renderização
    precacheImage(const AssetImage('assets/logo-var01.png'), context).then((_) {
      // Quando a imagem estiver em cache, inicia a animação de surgimento
      if (mounted) _logoAppearCtrl.forward();
    });
  }

  void _enterPhaseB() {
    if (!mounted) return;
    setState(() => _phaseB = true);
    _floatCtrl.stop();
    _ringCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 900), curve: Curves.decelerate);
    _bgFadeCtrl.forward();
    _barCtrl.reverse();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppHeroFadeRoute(page: const LoginCidadaoScreen()),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _bgFadeCtrl.dispose();
    _barCtrl.dispose();
    _logoAppearCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(children: [
        // Fundo fade-in
        AnimatedBuilder(
          animation: _bgFadeCtrl,
          builder: (_, child) => Opacity(opacity: _bgFade.value, child: child),
          child: AppBackground(child: const SizedBox.expand()),
        ),

        const Positioned(top: 0, left: 0, right: 0, child: AppTopLine()),

        // Conteúdo principal
        AnimatedBuilder(
          animation: Listenable.merge(
              [_floatCtrl, _pulseCtrl, _ringCtrl, _logoAppearCtrl]),
          builder: (_, __) => Stack(children: [
            // Logo centralizada, com fade e scale no surgimento
            Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: _logoAppearCtrl.value,
                child: Transform.scale(
                  scale: 0.92 + (0.08 * _logoAppearCtrl.value),
                  child: _buildLogoHero(),
                ),
              ),
            ),

            FadeTransition(
              opacity: _barFade,
              child: Align(
                alignment: const Alignment(0, 0.72),
                child: _buildProgress(),
              ),
            ),
          ]),
        ),

        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _barFade,
            child: const AppSplashFooter(),
          ),
        ),
      ]),
    );
  }

  Widget _buildLogoHero() {
    return Hero(
      tag: 'brand-logo',
      flightShuttleBuilder: (_, anim, dir, fromCtx, toCtx) {
        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) => _BrandLogoWidget(
            ringValue: _ringCtrl.value,
            pulseValue: _pulse.value,
            floatOffset: 0,
          ),
        );
      },
      child: _BrandLogoWidget(
        ringValue: _ringCtrl.value,
        pulseValue: _pulse.value,
        floatOffset: _phaseB ? 0 : _float.value,
      ),
    );
  }

  Widget _buildProgress() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 160,
          child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, __) => Stack(children: [
                    Container(
                        height: 2,
                        decoration: BoxDecoration(
                            color: AppColors.borderDim,
                            borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(
                        widthFactor: _progressCtrl.value,
                        child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.greenLt.withOpacity(0.5),
                                      blurRadius: 6)
                                ])))
                  ]))),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: Text(_labels[_step],
            key: ValueKey(_step), style: AppTextStyles.labelSmall),
      ),
      const SizedBox(height: 12),
      Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              _labels.length,
              (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _step ? 10 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          i == _step ? AppColors.greenLt : AppColors.borderMid,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: i == _step
                          ? [
                              BoxShadow(
                                  color: AppColors.greenLt.withOpacity(0.55),
                                  blurRadius: 7)
                            ]
                          : null,
                    ),
                  )))
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────
//  _BrandLogoWidget — ícone + nome da marca
//  (sem fallback visual — imagem só aparece quando pronta)
// ─────────────────────────────────────────────────────────────────

class _BrandLogoWidget extends StatelessWidget {
  final double ringValue;
  final double pulseValue;
  final double floatOffset;

  const _BrandLogoWidget({
    required this.ringValue,
    required this.pulseValue,
    required this.floatOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Transform.translate(
        offset: Offset(0, floatOffset),
        child: _buildIcon(),
      ),
      const SizedBox(height: 28),
      _buildBrandName(),
    ]);
  }

  Widget _buildIcon() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(alignment: Alignment.center, children: [
        // Glow
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.blueLt.withOpacity(0.18 * pulseValue),
              AppColors.blue.withOpacity(0.10 * pulseValue),
              Colors.transparent,
            ]),
          ),
        ),

        // Anéis
        Transform.rotate(
          angle: ringValue * 2 * math.pi,
          child: CustomPaint(
              size: const Size(138, 138), painter: ArcRingPainter()),
        ),
        Transform.rotate(
          angle: -ringValue * math.pi,
          child: CustomPaint(
              size: const Size(158, 158), painter: InnerRingPainter()),
        ),

        // Card da logo (gradiente, sombras) — invisível até imagem carregar
        // A imagem carrega por cima e o card só aparece junto com ela via opacity no pai
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2B6B), AppColors.primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.38 + 0.12 * pulseValue),
                blurRadius: 20 + 8 * pulseValue,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/logo-var01.png',
              width: 86,
              height: 86,
              fit: BoxFit.contain,
              // fallback transparente: não mostra nada até a imagem carregar
              frameBuilder: (ctx, child, frame, wasSyncLoaded) {
                if (wasSyncLoaded || frame != null) {
                  // Imagem pronta — mostra com fade
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeIn,
                      child: child,
                    ),
                  );
                }
                // Nada visível (mantém o espaço, mas vazio)
                return const SizedBox.shrink();
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Ponto de status
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: AppColors.greenLt,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.navyDeep, width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.greenLt.withOpacity(pulseValue),
                    blurRadius: 8 + pulseValue * 8)
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBrandName() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          const TextSpan(text: 'Conecta', style: AppTextStyles.appNameConecta),
          TextSpan(
            text: 'Saúde',
            style: AppTextStyles.appNameSaude.copyWith(shadows: [
              Shadow(color: AppColors.blueLt.withOpacity(0.4), blurRadius: 14)
            ]),
          ),
          TextSpan(
            text: 'PI',
            style: AppTextStyles.appNamePi.copyWith(shadows: [
              Shadow(color: AppColors.greenLt.withOpacity(0.5), blurRadius: 14)
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderDim))),
        child:
            const Text('SUA SAÚDE CONECTADA.', style: AppTextStyles.labelSmall),
      ),
    ]);
  }
}
