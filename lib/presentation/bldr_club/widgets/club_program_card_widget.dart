import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ClubProgramCardWidget extends StatelessWidget {
  const ClubProgramCardWidget({
    super.key,
    required this.program,
    required this.onStart,
    this.onTap,
  });

  final Map<String, dynamic> program;
  final VoidCallback onStart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = (program['name'] ?? 'Programa').toString();
    final tagline = (program['tagline'] ?? '').toString();
    final img = program['cover_image']?.toString();
    final level = (program['level'] ?? '').toString();
    final weeks = program['duration_weeks']?.toString();
    final minutes = program['minutes_per_day']?.toString();

    return GestureDetector(
      onTap: onTap, // Ação de clique para navegar para a tela de detalhes
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // cover
            Container(
              height: 12.h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: img != null && img.isNotEmpty
                    ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
                    : null,
                color: AppTheme.surfaceDark,
              ),
            ),
            // body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: 0.4.h),
                    Expanded(
                      child: Text(tagline,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          )),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: [
                        _miniChip(level.isEmpty ? 'Nível' : level),
                        _miniChip('${weeks ?? '--'} sem'),
                        _miniChip('${minutes ?? '--'} min/dia'),
                      ],
                    ),
                    SizedBox(height: 1.2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryBlack,
                          padding: EdgeInsets.symmetric(vertical: 1.1.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Iniciar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Text(
        t,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}