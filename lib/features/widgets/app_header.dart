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
  final VoidCallback onLogout;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;

  const AppHeader({
    super.key,
    required this.userName,
    this.userPhoto,
    required this.onLogout,
    this.onMenuPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Container(
      width: double.infinity, // Garante que o container ocupe toda a largura disponível
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
          child: Row(
            children: [
              // Hamburguer (se fornecido)
              if (onMenuPressed != null) ...[
                _IconBtn(icon: Icons.menu_rounded, onTap: onMenuPressed!),
                const SizedBox(width: 12),
              ],

              // Logo aparece APENAS se NÃO for Desktop (Mobile/Tablet)
              if (!isDesktop) _buildLogo(),

              // Spacer: Empurra absolutamente TUDO o que vem depois para a extrema direita
              const Spacer(),

              // BLOCO DA DIREITA: Agrupa a Saudação, Notificação e Avatar para ficarem sempre juntos
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Envolvemos a Saudação e o Avatar com InkWell para navegar ao perfil
                  InkWell(
                    onTap: onProfilePressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Saudação ("Olá, ...")
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
                          // Avatar
                          _buildAvatar(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Notificações
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
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A8F), AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 10),
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
                    color: Colors.white,
                    height: 1.1),
              ),
              TextSpan(
                text: 'Saúde',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
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
                    fontSize: 11,
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

  Widget _buildAvatar() {
  // 1. Criamos uma validação real: tem que ser diferente de null E não pode ser um texto vazio
  final hasValidPhoto = userPhoto != null && userPhoto!.trim().isNotEmpty;

  return CircleAvatar(
    radius: 18,
    backgroundColor: AppColors.primaryDeep,
    
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
            color: Colors.white.withOpacity(0.08),
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