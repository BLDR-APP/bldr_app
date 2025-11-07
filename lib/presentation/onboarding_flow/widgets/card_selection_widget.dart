import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart'; // Mantive seu import

class CardSelectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final List<String> selectedOptions;
  final Function(List<String>) onOptionsChanged;
  final bool multiSelect;

  const CardSelectionWidget({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionsChanged,
    this.multiSelect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        // Ajuste o aspect ratio se necessário para as imagens
        childAspectRatio: 0.9, // Um pouco mais alto para acomodar melhor a imagem
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];

        // --- CORREÇÃO: Leitura segura das chaves ---
        final title = option['title']?.toString() ?? ''; // Lê 'title' com segurança
        final iconName = option['icon']?.toString() ?? ''; // Lê 'icon' com segurança
        final imagePath = option['imagePath']?.toString() ?? ''; // Lê 'imagePath' com segurança
        // --- FIM DA CORREÇÃO ---

        final isSelected = selectedOptions.contains(title);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            List<String> newSelection = List.from(selectedOptions);

            if (multiSelect) {
              if (isSelected) {
                newSelection.remove(title);
              } else {
                newSelection.add(title);
              }
            } else {
              // Para seleção única, sempre usa o 'title' da opção atual
              newSelection = isSelected ? [] : [title];
            }

            onOptionsChanged(newSelection);
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w), // Adicionado padding
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentGold.withAlpha(25) // Alpha mais sutil (0.1 * 255 = 25)
                  : AppTheme.cardDark,
              border: Border.all(
                color: isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
              children: [
                // --- CORREÇÃO: Mostra Ícone OU Imagem ---
                Expanded( // Usa Expanded para a imagem/ícone preencher o espaço
                  child: FittedBox( // Ajusta o tamanho do conteúdo interno
                    fit: BoxFit.contain, // Garante que a imagem/ícone caiba
                    child: (imagePath.isNotEmpty)
                        ? Image.asset(
                      imagePath,
                      // Adicione `fit`, `errorBuilder` se necessário
                    )
                        : (iconName.isNotEmpty)
                        ? CustomIconWidget( // Usa seu CustomIconWidget se tiver ícone
                      iconName: iconName,
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.textSecondary,
                      size: 4.w, // Mantém o tamanho original
                    )
                        : Container(), // Se não tiver nem imagem nem ícone
                  ),
                ),
                // --- FIM DA CORREÇÃO ---

                SizedBox(height: 1.h), // Espaço menor
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1, // Evita quebra de linha no título
                  overflow: TextOverflow.ellipsis, // Adiciona '...' se o título for muito longo
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color:
                    isSelected ? AppTheme.accentGold : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                // O ícone de check (se multiSelect) não precisa mais estar aqui,
                // a borda e cor de fundo já indicam a seleção.
                // Removido o bloco if (isSelected && multiSelect)...
              ],
            ),
          ),
        );
      },
    );
  }
}