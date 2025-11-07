import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExportProgressWidget extends StatelessWidget {
  final Function(String format) onExport;

  const ExportProgressWidget({
    Key? key,
    required this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.dividerGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Exportar relatório de progresso',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Escolha o formato para exportar o seu progresso fitness',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 3.h),
          _buildExportOption(
            'PDF Report',
            'Relatório de progresso completo com gráficos e análises',
            'picture_as_pdf',
            AppTheme.errorRed,
            'PDF',
          ),
          SizedBox(height: 2.h),
          _buildExportOption(
            'Excel',
            'Exportação de dados em Raw para análise detalhada',
            'table_chart',
            AppTheme.successGreen,
            'CSV',
          ),
          SizedBox(height: 2.h),
          _buildExportOption(
            'Compartilhar sumário',
            'Sumário para rede social ou personal trainers',
            'share',
            AppTheme.accentGold,
            'Share',
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    String description,
    String iconName,
    Color color,
    String format,
  ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => onExport(format),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerGray),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.textSecondary,
                size: 5.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
