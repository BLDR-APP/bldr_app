import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VideoBackgroundWidget extends StatefulWidget {
  final Widget child;

  const VideoBackgroundWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // A função de inicialização do vídeo foi removida
    // para evitar o erro de conexão.
    _isVideoInitialized = false;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fundo estático como padrão
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlack,
                  AppTheme.surfaceDark,
                  AppTheme.primaryBlack,
                ],
              ),
            ),
          ),
        ),
        // Overlay escuro para melhorar a legibilidade do texto
        Positioned.fill(
          child: Container(
            color: AppTheme.primaryBlack.withValues(alpha: 0.6),
          ),
        ),
        // Conteúdo da tela
        widget.child,
      ],
    );
  }
}