import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ClubFeaturedProgramsWidget extends StatelessWidget {
  const ClubFeaturedProgramsWidget({
    super.key,
    required this.programs,
    required this.onTapStart,
    required this.onTapCard,
  });

  final List<Map<String, dynamic>> programs;
  final void Function(Map<String, dynamic>) onTapStart;
  final void Function(Map<String, dynamic>) onTapCard;

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Em destaque',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.2.h),
        SizedBox(
          height: 22.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: programs.length,
            separatorBuilder: (_, __) => SizedBox(width: 3.w),
            itemBuilder: (_, i) {
              final p = programs[i];
              return _FeaturedCard(
                program: p,
                onStart: () => onTapStart(p),
                onTap: () => onTapCard(p), // Chamando a nova função de navegação
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.program,
    required this.onStart,
    required this.onTap,
  });
  final Map<String, dynamic> program;
  final VoidCallback onStart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = program['cover_image']?.toString();
    final name = (program['name'] ?? 'Programa').toString();
    final weeks = program['duration_weeks']?.toString();
    final minutes = program['minutes_per_day']?.toString();

    return GestureDetector(
      onTap: onTap, // Ação de clique para navegar para a tela de detalhes
      child: Container(
        width: 70.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.35)),
          image: img != null && img.isNotEmpty
              ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.65),
                Colors.transparent,
              ],
            ),
          ),
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _chip('${minutes ?? '--'} min/dia'),
                        SizedBox(width: 2.w),
                        _chip('${weeks ?? '--'} sem'),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack,
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Iniciar'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}