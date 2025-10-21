// club_exercise_categories_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubExerciseCategoriesWidget extends StatelessWidget {
  /// Lista base para contagem dos tipos. Pode ser exercises **ou** templates do CLUB.
  /// Aceita chaves:
  ///  - 'type' => 'Força' | 'HIIT' (preferível no CLUB)
  ///  - fallback: 'exercise_type' => 'strength/compound' → Força ; 'hiit/cardio/plyometric' → HIIT
  final List<Map<String, dynamic>> exercises;

  /// Callback de categoria (Treinos): passa 'Força' ou 'HIIT'
  final Function(String) onCategoryTap;

  /// Callback para filtro de nível (1..4) — null = 'Todos'
  final Function(int?)? onLevelTap;

  /// Realce da seleção atual
  final int? selectedLevel; // null => Todos
  final String? selectedCategory; // 'Força' | 'HIIT' | null

  const ClubExerciseCategoriesWidget({
    Key? key,
    required this.exercises,
    required this.onCategoryTap,
    this.onLevelTap,
    this.selectedLevel,
    this.selectedCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counts = _getCounts(); // {forca, hiit}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.2.h),

        // Filtro de Nível
        _LevelChipsRow(
          selected: selectedLevel,
          onTap: onLevelTap,
        ),

        SizedBox(height: 2.2.h),

        // Filtro de Treinos (Força / HIIT)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 3.w,
          runSpacing: 2.h,
          children: [
            _CategoryCardVIP(
              name: 'Força',
              icon: 'fitness_center',
              count: counts.forca,
              highlighted: (selectedCategory ?? '').toLowerCase() == 'força' ||
                  (selectedCategory ?? '').toLowerCase() == 'forca',
              color: AppTheme.accentGold,
              onTap: () => onCategoryTap('Força'),
            ),
            _CategoryCardVIP(
              name: 'HIIT',
              icon: 'flash_on',
              count: counts.hiit,
              highlighted: (selectedCategory ?? '').toLowerCase() == 'hiit',
              color: AppTheme.warningAmber,
              onTap: () => onCategoryTap('HIIT'),
            ),
          ],
        ),
      ],
    );
  }

  /// Conta itens por tipo, aceitando várias nomenclaturas
  _Counts _getCounts() {
    int forca = 0;
    int hiit = 0;

    for (final e in exercises) {
      final t0 = (e['type'] ?? e['exercise_type'] ?? '').toString().toLowerCase();

      if (t0 == 'força' || t0 == 'forca' || t0 == 'strength' || t0 == 'compound') {
        forca++;
      } else if (t0 == 'hiit' || t0 == 'cardio' || t0 == 'plyometric') {
        hiit++;
      }
    }
    return _Counts(forca: forca, hiit: hiit);
  }
}

/* ====================== SUBWIDGETS ====================== */

class _LevelChipsRow extends StatelessWidget {
  const _LevelChipsRow({required this.selected, required this.onTap});
  final int? selected; // null => Todos
  final Function(int?)? onTap;

  @override
  Widget build(BuildContext context) {
    final levels = <int?>[null, 1, 2, 3, 4]; // null = Todos

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      child: Row(
        children: levels.map((lvl) {
          final isSelected = selected == lvl;
          final label = lvl == null ? 'Todos' : lvl.toString();

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onTap?.call(lvl),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppTheme.accentGold,
              backgroundColor: const Color(0xFF1A1A1A),
              shape: const StadiumBorder(
                side: BorderSide(color: Color(0x22D4AF37)),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryCardVIP extends StatefulWidget {
  const _CategoryCardVIP({
    required this.name,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  final String name;
  final String icon;
  final int count;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  State<_CategoryCardVIP> createState() => _CategoryCardVIPState();
}

class _CategoryCardVIPState extends State<_CategoryCardVIP>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.highlighted ? widget.color : AppTheme.dividerGray;
    final glow = widget.highlighted
        ? [BoxShadow(color: widget.color.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 4))]
        : [const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))];

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 38.w,
          height: 18.h,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: glow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0.20),
                        widget.color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.color.withOpacity(0.35)),
                  ),
                  child: CustomIconWidget(
                    iconName: widget.icon,
                    color: widget.color,
                    size: 8.w,
                  ),
                ),
                SizedBox(height: 1.6.h),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  '${widget.count} treinos',
                  textAlign: TextAlign.center,
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ====================== Helpers ====================== */

class _Counts {
  final int forca;
  final int hiit;
  const _Counts({required this.forca, required this.hiit});
}
