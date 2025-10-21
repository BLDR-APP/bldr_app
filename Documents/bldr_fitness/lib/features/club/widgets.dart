import 'package:flutter/material.dart';

const _gold = Color(0xFFD4AF37);

/// ✅ Linha de badges horizontal e alinhada (quebra linha se precisar).
class BldrBadgeRow extends StatelessWidget {
  const BldrBadgeRow({
    super.key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: alignment,
        children: children,
      ),
    );
  }
}

/// Badge dourado unificado (texto em caps) com ícone opcional.
class BldrGoldBadge extends StatelessWidget {
  const BldrGoldBadge(
      this.text, {
        super.key,
        this.icon,
      });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (icon != null) {
      children.add(Icon(icon, size: 14, color: _gold));
      children.add(const SizedBox(width: 4));
    }

    children.add(
      Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _gold,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1.0, // ajuda a alinhar baselines
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.12),
        border: Border.all(color: _gold.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Converte valores de nível vindos como `String` **ou** `enum`.
String levelLabel(Object? v) {
  if (v == null) return 'Todos os níveis';

  String key;
  if (v is String) {
    key = v;
  } else {
    final s = v.toString();
    final dot = s.lastIndexOf('.');
    key = dot >= 0 ? s.substring(dot + 1) : s;
  }

  key = key.trim().toLowerCase();

  key = key
      .replaceAll('á', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  switch (key) {
    case 'iniciante':
    case 'iniciantes':
      return 'Iniciante';
    case 'intermediario':
      return 'Intermediário';
    case 'avancado':
      return 'Avançado';
    case 'todos':
    case 'todos os niveis':
    case 'all':
    case 'any':
      return 'Todos os níveis';
    default:
      return 'Todos os níveis';
  }
}
