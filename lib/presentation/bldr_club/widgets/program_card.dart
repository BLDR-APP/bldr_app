import 'package:flutter/material.dart';

const _gold = Color(0xFFD4AF37);

/// Card reutilizável para programas de treino (sem dados fake).
class ProgramCard extends StatelessWidget {
  const ProgramCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.thumbnailUrl,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121214),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22D4AF37)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(thumbnailUrl!, fit: BoxFit.cover),
              )
            else
              const SizedBox(height: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LevelBadgeDense(text: badge),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: _gold,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Ver programa'),
                        ),
                      ],
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
}

/// Badge compacta
class _LevelBadgeDense extends StatelessWidget {
  const _LevelBadgeDense({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: _gold,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      height: 1.0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.12),
        border: Border.all(color: _gold.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text.toUpperCase(), style: style),
    );
  }
}

