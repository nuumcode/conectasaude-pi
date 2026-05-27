// ═══════════════════════════════════════════════════════════════════
//  app_header.dart  —  ConectaSaúdePI
//  ✅ Zero overflow: saudação usa Flexible + ellipsis
//  ✅ Mobile: hamburguer → logo → spacer → [Olá, X + notif + avatar] juntos na direita
//  ✅ Desktop: spacer → [Olá, X + notif + avatar] juntos na direita (Logo oculta)
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

class AppHeader extends StatelessWidget {
  final String userName;
  final String? userPhoto;
  final String? title;
  final VoidCallback onLogout;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;

  const AppHeader({
    super.key,
    required this.userName,
    this.userPhoto,
    this.title,
    required this.onLogout,
    this.onMenuPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2B6B), AppColors.primaryDeep],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16, vertical: 12),
          child: Row(
            children: [
              // Hamburguer (se fornecido)
              if (onMenuPressed != null) ...[
                _IconBtn(icon: Icons.menu_rounded, onTap: onMenuPressed!),
                const SizedBox(width: 12),
              ],

              // Título ou Logo
              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                )
              else if (!isDesktop)
                _buildLogo(),

              // Spacer
              const Spacer(),

              // BLOCO DA DIREITA
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onProfilePressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isDesktop ? 220 : 110),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  'Olá, $userName!',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isDesktop ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          _buildAvatar(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  _IconBtn(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {},
                      badge: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    height: 1.1),
              ),
              const TextSpan(
                text: 'Saúde',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const TextSpan(
                text: 'PI',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent),
              ),
            ]),
          ),
        ],
      );

  Widget _buildAvatar() {
  // 1. Criamos uma validação real: tem que ser diferente de null E não pode ser um texto vazio
  final hasValidPhoto = userPhoto != null && userPhoto!.trim().isNotEmpty;

  return CircleAvatar(
    radius: 18,
    backgroundColor: Colors.white.withOpacity(0.2),
    
    // Tentamos carregar a imagem da rede se a URL for válida
    backgroundImage: hasValidPhoto ? NetworkImage(userPhoto!) : null,
    
    // Evita que o app trave ou suma com tudo se o link da imagem estiver quebrado (Erro 404, etc)
    onBackgroundImageError: hasValidPhoto 
        ? (exception, stackTrace) {
            debugPrint('Erro ao carregar a foto do usuário: $exception');
          }
        : null,

    // O child (as iniciais do nome) só aparece se NÃO tiver foto válida
    child: !hasValidPhoto
        ? Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 14),
          )
        : null,
  );
}
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _IconBtn({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: SizedBox(
                width: 38,
                height: 38,
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
                    color: AppColors.accent, shape: BoxShape.circle),
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
