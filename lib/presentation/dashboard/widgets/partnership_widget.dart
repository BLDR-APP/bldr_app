import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class Partner {
  final String imageUrl;
  final String tagline;
  final Color borderColor;
  const Partner({
    required this.imageUrl,
    required this.tagline,
    required this.borderColor,
  });
}

class PartnershipWidget extends StatelessWidget {
  const PartnershipWidget({Key? key}) : super(key: key);

  // 🔁 Defina aqui os parceiros (o primeiro é exatamente o que você já tinha)
  List<Partner> get partners => const [
        Partner(
          imageUrl: 'https://i.postimg.cc/mrCGHrBP/Don-t-Eat.png',
          tagline:
              'Sua proteína com sabor de sobremesa e preço acessível',
          borderColor: Color(0xFFFF69B4),
        ),
        // ➕ Exemplo de novo parceiro (substitua os valores):
        Partner(
          imageUrl: 'https://i.postimg.cc/V6Kr8HfZ/PILHEI-SHOT.png',
          tagline: 'Sua dose de energia instantânea, a qualquer hora',
          borderColor: Color(0xFFF1F866),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowBlack,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'handshake',
                color: AppTheme.accentGold,
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              'Parceiros',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          SizedBox(height: 3.h),

          // ⬇️ Repetimos o MESMO card para cada parceiro, mantendo o layout
          ...List.generate(partners.length, (i) {
            final p = partners[i];
            return Column(
              children: [
                _partnerCard(
                  imageUrl: p.imageUrl,
                  tagline: p.tagline,
                  borderColor: p.borderColor,
                ),
                if (i != partners.length - 1) SizedBox(height: 2.h), // espaçamento entre cards
              ],
            );
          }),
        ],
      ),
    );
  }

  // ⚙️ Mesmo layout do seu card original
  Widget _partnerCard({
    required String imageUrl,
    required String tagline,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray, width: 1),
      ),
      child: Column(
        children: [
          Text(
            '',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 8.h,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: CustomImageWidget(
                imageUrl: imageUrl,
                height: 6.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            tagline,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
