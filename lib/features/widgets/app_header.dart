// ═══════════════════════════════════════════════════════════════════
//  app_header.dart  —  ConectaSaúdePI
//  Header reutilizável (PreferredSizeWidget)
//
//  Mobile:  Hamburguer + Logo + saudação + avatar
//  Desktop: só Logo + saudação + avatar (sem hamburguer)
//
//  Baseado na estrutura do PremiumHeader (nuum_gestao) mas
//  adaptado à identidade visual do ConectaSaúdePI.
//
//  Uso:
//    Column(children: [
//      AppHeader(userName: ..., userPhoto: ..., onLogout: ...),
//      Expanded(child: conteúdo),
//    ])
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

class AppHeader extends StatelessWidget {
  final String userName;
  final String? userPhoto;
  final VoidCallback onLogout;
  final VoidCallback? onMenuPressed; // null = sem hamburguer (desktop)

  const AppHeader({
    super.key,
    required this.userName,
    this.userPhoto,
    required this.onLogout,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Container(
      // Gradiente escuro do header — identidade ConectaSaúdePI
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bgMid, AppColors.bgBase],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16, vertical: 12),
          child: Row(children: [
            // ── Hamburguer (só mobile) ────────────────────────
            if (onMenuPressed != null) ...[
              _HeaderIconBtn(
                icon: Icons.menu_rounded,
                onTap: onMenuPressed!,
              ),
              const SizedBox(width: 12),
            ],

            // ── Logo + Nome da marca ──────────────────────────
            _buildLogo(),

            const Spacer(),

            // ── Saudação ──────────────────────────────────────
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Olá, $userName!',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),

            // ── Notificações ──────────────────────────────────
            _HeaderIconBtn(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
              badge: 2,
            ),

            const SizedBox(width: 8),

            // ── Avatar / Saudação mobile ──────────────────────
            _buildAvatar(context),
          ]),
        ),
      ),
    );
  }

  // ── Logo no header ──────────────────────────────────────────────
  Widget _buildLogo() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A8F), AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.30), blurRadius: 10),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo-var01.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    CustomPaint(painter: CrossEcgPainter()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(children: [
              const TextSpan(
                text: 'Conecta\n',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.1),
              ),
              TextSpan(
                text: 'Saúde',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blueLt,
                    shadows: [
                      Shadow(
                          color: AppColors.blueLt.withOpacity(0.5),
                          blurRadius: 8)
                    ]),
              ),
              TextSpan(
                text: 'PI',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenLt,
                    shadows: [
                      Shadow(
                          color: AppColors.greenLt.withOpacity(0.5),
                          blurRadius: 8)
                    ]),
              ),
            ]),
          ),
        ],
      );

  // ── Avatar com saudação mobile inline ──────────────────────────
  Widget _buildAvatar(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDesktop) ...[
          Text('Olá, $userName!',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(width: 12),
        ],
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryDeep,
          backgroundImage: userPhoto != null ? NetworkImage(userPhoto!) : null,
          child: userPhoto == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                )
              : null,
        ),
      ],
    );
  }
}

// ── Botão de ícone do header ─────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.primaryDeep, shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      );
}
