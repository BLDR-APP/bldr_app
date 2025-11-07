import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EditProfileDialogWidget extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final Function(String name, String email, String phone) onSave;

  const EditProfileDialogWidget({
    Key? key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditProfileDialogWidget> createState() =>
      _EditProfileDialogWidgetState();
}

class _EditProfileDialogWidgetState extends State<EditProfileDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.dialogDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar Perfil',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: AppTheme.accentGold),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
            ),

            SizedBox(height: 2.h),

            // Email (readonly para Supabase)
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
                suffixIcon: Tooltip(
                  message: 'Email não pode ser alterado',
                  child: Icon(Icons.info, color: AppTheme.textSecondary),
                ),
              ),
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            SizedBox(height: 2.h),

            // Telefone (opcional)
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Telefone (opcional)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.phone, color: AppTheme.accentGold),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 3.h),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Nome é obrigatório'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                      widget.onSave(
                        name,
                        _emailController.text.trim(),
                        _phoneController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
