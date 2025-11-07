import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

// ===== NOVOS IMPORTS ADICIONADOS =====
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// ===================================

import '../../core/app_export.dart';
import '../../models/subscription_plan.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/profile_notifier.dart';
import '../../services/user_service.dart';
import './widgets/confirmation_dialog_widget.dart';
import './widgets/edit_profile_dialog_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_section_widget.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  UserProfile? _userProfile;
  UserSubscription? _userSubscription;
  bool _isLoading = true;
  String? _error;

  late ProfileNotifier _profileNotifier;

  bool _notificationsEnabled = false;
  bool _dataSyncEnabled = true;
  bool _privacyModeEnabled = false;

  // ===== NOVA VARIÁVEL DE ESTADO ADICIONADA =====
  bool _isTogglingNotifications = false;
  // ==========================================

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    _profileNotifier.addListener(_handleProfileUpdate);
  }

  void _handleProfileUpdate() {
    print("PROFILE DRAWER: Notificação de atualização recebida! Recarregando dados do perfil...");
    if (mounted) {
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _profileNotifier.removeListener(_handleProfileUpdate);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      final subscription =
      await PaymentService.instance.getCurrentUserSubscription();

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _userSubscription = subscription;

        // ===== CARREGA O ESTADO DA NOTIFICAÇÃO DO BANCO =====
        _notificationsEnabled = profile?.notificationsEnabled ?? false;
        // ====================================================

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => EditProfileDialogWidget(
        currentName: _userProfile!.fullName,
        currentEmail: _userProfile!.email,
        currentPhone: '',
        onSave: (name, email, phone) async {
          try {
            final updatedProfile =
            await UserService.instance.updateCurrentUserProfile(
              updates: {
                'full_name': name,
              },
            );

            if (updatedProfile != null) {
              setState(() {
                _userProfile = updatedProfile;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perfil atualizado com sucesso!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar perfil: $e'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPlanUpgradeDialog() async {
    try {
      final plans = await PaymentService.instance.getSubscriptionPlans();

      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.dialogDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Escolha seu Plano',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Desbloqueie todo o potencial do BLDR',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final isCurrentPlan =
                          _userSubscription?.planId == plan.id;

                      return Container(
                        margin: EdgeInsets.only(bottom: 3.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: plan.isPopular
                                ? AppTheme.accentGold
                                : AppTheme.dividerGray,
                            width: plan.isPopular ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan.name,
                                  style: AppTheme.darkTheme.textTheme.titleLarge
                                      ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (plan.isPopular)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3.w,
                                      vertical: 0.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'POPULAR',
                                      style: AppTheme
                                          .darkTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: AppTheme.primaryBlack,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              plan.description,
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  plan.monthlyPriceText,
                                  style: AppTheme
                                      .darkTheme.textTheme.headlineSmall
                                      ?.copyWith(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'ou ${plan.annualPriceText}',
                                  style: AppTheme.darkTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            ...plan.features.map((feature) => Padding(
                              padding: EdgeInsets.only(bottom: 1.h),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successGreen,
                                    size: 4.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: AppTheme
                                          .darkTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            SizedBox(height: 2.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isCurrentPlan
                                    ? null
                                    : () {
                                  Navigator.pop(context);
                                  _navigateToCheckout(plan);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrentPlan
                                      ? AppTheme.inactiveGray
                                      : AppTheme.accentGold,
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isCurrentPlan
                                      ? 'Plano Atual'
                                      : 'Escolher Plano',
                                  style: AppTheme
                                      .darkTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: isCurrentPlan
                                        ? AppTheme.textSecondary
                                        : AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar planos: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _navigateToCheckout(SubscriptionPlan plan) {
    Navigator.pushNamed(
      context,
      AppRoutes.checkoutScreen,
      arguments: {
        'plan': plan,
        'billingPeriod': 'monthly',
      },
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alterar foto de perfil',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _handleCameraCapture();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerGray),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt,
                                color: AppTheme.accentGold, size: 32),
                            SizedBox(height: 1.h),
                            Text(
                              'Câmera',
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _handleGallerySelection();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerGray),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library,
                                color: AppTheme.accentGold, size: 32),
                            SizedBox(height: 1.h),
                            Text(
                              'Galeria',
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCameraCapture() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadProfileImage(photo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao usar a câmera: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _handleGallerySelection() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        await _uploadProfileImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao escolher imagem: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    if (_userProfile == null) return;

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('Usuário não encontrado. Faça login novamente.');
      }

      final file = File(imageFile.path);
      final fileExtension = imageFile.path.split('.').last;

      final storagePath = '$currentUserId/profile.$fileExtension';

      await supabase.storage.from('Images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = supabase.storage
          .from('Images')
          .getPublicUrl(storagePath);

      final updatedProfile =
      await UserService.instance.updateCurrentUserProfile(
        updates: {
          'avatar_url': publicUrl,
        },
      );

      if (updatedProfile != null) {
        if (!mounted) return;
        setState(() {
          _userProfile = updatedProfile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar foto: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  // ===== NOVA FUNÇÃO DE NOTIFICAÇÃO ADICIONADA =====
  Future<void> _toggleNotifications(bool newValue) async {
    if (_isTogglingNotifications) return;

    setState(() {
      _isTogglingNotifications = true;
      _notificationsEnabled = newValue; // Atualização otimista
    });

    try {
      // Pega a instância do Firebase Messaging
      final fcm = FirebaseMessaging.instance;

      // Prepara o mapa de dados para o Supabase
      Map<String, dynamic> updates = {
        'notifications_enabled': newValue,
      };

      if (newValue == true) {
        // 1. Pedir permissão ao usuário
        NotificationSettings settings = await fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // 2. Obter o token FCM
          final fcmToken = await fcm.getToken();

          if (fcmToken != null) {
            // 3. Adicionar o token aos 'updates' para salvar no DB
            updates['fcm_token'] = fcmToken;
            print('Token FCM obtido e pronto para salvar: $fcmToken');
          } else {
            throw Exception('Não foi possível obter o token FCM.');
          }
        } else {
          // Usuário não deu permissão
          throw Exception('Permissão de notificação negada pelo usuário.');
        }
      } else {
        // Se o usuário está desativando as notificações
        // 1. Remover o token do DB
        updates['fcm_token'] = null;

        // 2. (Opcional) Invalidar o token atual
        await fcm.deleteToken();
        print('Token FCM deletado.');
      }

      // 3. ATUALIZAR O BANCO DE DADOS (Supabase)
      final updatedProfile = await UserService.instance
          .updateCurrentUserProfile(updates: updates);

      if (updatedProfile != null) {
        if (!mounted) return;
        setState(() {
          _userProfile = updatedProfile;
          // Garante que o estado local é o que veio do banco
          _notificationsEnabled = updatedProfile.notificationsEnabled ?? newValue;
        });
      } else {
        throw Exception('Não foi possível atualizar o perfil');
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar notificações: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      // Reverte o switch visualmente se der erro
      setState(() {
        _notificationsEnabled = !newValue;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingNotifications = false;
        });
      }
    }
  }
  // ===============================================

  void _showOptionsSheet({
    required String title,
    required List<String> options,
    required String currentValue,
    required void Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dialogDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
              SizedBox(height: 2.h),
              ...options.map((opt) {
                final selected = opt == currentValue;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt,
                      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                  trailing: selected
                      ? const Icon(Icons.check, color: AppTheme.accentGold)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(opt);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showMeasurementsDialog() {
    if (_userProfile == null) return;

    final heightController = TextEditingController(
      text: _userProfile!.heightCm?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: _userProfile!.targetWeightKg?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Medidas Corporais',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              _buildMeasurementField('Altura (cm)', heightController),
              SizedBox(height: 2.h),
              _buildMeasurementField('Peso Alvo (kg)', weightController),
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
                      onPressed: () async {
                        try {
                          final updates = <String, dynamic>{};

                          if (heightController.text.isNotEmpty) {
                            final height = int.tryParse(heightController.text);
                            if (height != null) updates['height_cm'] = height;
                          }

                          if (weightController.text.isNotEmpty) {
                            final weight =
                            double.tryParse(weightController.text);
                            if (weight != null) {
                              updates['target_weight_kg'] = weight;
                            }
                          }

                          if (updates.isNotEmpty) {
                            final updatedProfile = await UserService.instance
                                .updateCurrentUserProfile(updates: updates);

                            if (updatedProfile != null) {
                              setState(() {
                                _userProfile = updatedProfile;
                              });
                            }
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medidas salvas!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar: $e'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
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
      ),
    );
  }

  Widget _buildMeasurementField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: 'Digite $label',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  String _getCurrentPlanName() {
    if (_userSubscription == null) return 'Plano Gratuito';

    if (_userSubscription!.status != 'active') {
      return 'Plano Gratuito';
    }

    switch (_userSubscription!.planId) {
      case 'ffa05840-0212-46eb-9f80-2dbab9c362a8':
        return 'BLDR CORE';
      case 'd082af8c-216a-4499-a1f6-1fb84ac08a5f':
        return 'BLDR CLUB';
      default:
        return 'Plano Premium';
    }
  }

  bool get _isPremium {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active';
  }

  bool get _isClubMember {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active' &&
        _userSubscription!.planId ==
            'd082af8c-216a-4499-a1f6-1fb84ac08a5f';
  }

  // --- CORREÇÃO: As funções abaixo foram movidas para dentro da classe ---

  String _getGoalDisplayName(String? goal) {
    if (goal == null) return 'Não definido';
    switch (goal.toLowerCase()) {
      case 'weight_loss':
        return 'Perda de Peso';
      case 'muscle_gain':
        return 'Ganho de Massa | Hipertrofia';
      case 'strength':
        return 'Força';
      case 'endurance':
        return 'Resistência';
      case 'general_fitness':
        return 'Condicionamento Geral';
      default:
        return goal;
    }
  }

  String _getActivityDisplayName(String? activity) {
    if (activity == null) return 'Não definido';
    switch (activity.toLowerCase()) {
      case 'sedentary':
        return 'Sedentário';
      case 'lightly_active':
        return 'Levemente Ativo';
      case 'moderately_active':
        return 'Moderadamente Ativo';
      case 'very_active':
        return 'Muito Ativo';
      case 'extremely_active':
        return 'Extremamente Ativo';
      default:
        return activity;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Drawer(
        backgroundColor: AppTheme.primaryBlack,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentGold,
          ),
        ),
      );
    }

    if (_error != null || _userProfile == null) {
      return Drawer(
        backgroundColor: AppTheme.primaryBlack,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Erro ao carregar perfil',
                style: const TextStyle(color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: AppTheme.primaryBlack,
      child: SafeArea(
        child: Column(
          children: [
            ProfileHeaderWidget(
              userName: _userProfile!.fullName,
              userEmail: _userProfile!.email,
              profileImageUrl: _userProfile!.avatarUrl ??
                  "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
              isPremiumMember: _isPremium,
              isClubMember: _isClubMember,
              onProfileImageTap: _showImagePickerDialog,
            ),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              color: AppTheme.dividerGray,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'INFORMAÇÕES PESSOAIS',
                      items: [
                        ProfileSectionItem(
                          iconName: 'edit',
                          title: 'Editar Perfil',
                          subtitle: 'Atualizar nome, email, telefone',
                          onTap: _showEditProfileDialog,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'PLANO E ASSINATURA',
                      items: [
                        ProfileSectionItem(
                          iconName: 'attach_money',
                          title: 'Plano Atual',
                          subtitle: _getCurrentPlanName(),
                          trailing: _isPremium
                              ? const Icon(
                            Icons.verified,
                            color: AppTheme.accentGold,
                            size: 20,
                          )
                              : null,
                        ),
                        if (!_isPremium)
                          ProfileSectionItem(
                            iconName: 'arrow_upward',
                            title: 'Fazer Upgrade',
                            subtitle: 'Desbloquear recursos premium',
                            onTap: _showPlanUpgradeDialog,
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'CONFIGURAÇÕES DE TREINO',
                      items: [
                        ProfileSectionItem(
                          iconName: 'fitness_center',
                          title: 'Objetivo',
                          subtitle:
                          _getGoalDisplayName(_userProfile!.fitnessGoal),
                          onTap: () => _showOptionsSheet(
                            title: 'Selecionar Objetivo',
                            options: const [
                              'Perda de Peso',
                              'Ganho de Massa | Hipertrofia',
                            ],
                            currentValue:
                            _getGoalDisplayName(_userProfile!.fitnessGoal),
                            onSelected: (value) async {
                              String dbValue;
                              switch (value) {
                                case 'Perda de Peso':
                                  dbValue = 'weight_loss';
                                  break;
                                case 'Ganho de Massa | Hipertrofia':
                                  dbValue = 'muscle_gain';
                                  break;
                                default:
                                  dbValue = 'general_fitness';
                              }

                              try {
                                final updatedProfile = await UserService
                                    .instance
                                    .updateCurrentUserProfile(
                                    updates: {'fitness_goal': dbValue});
                                if (updatedProfile != null) {
                                  setState(() {
                                    _userProfile = updatedProfile;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao atualizar: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        ProfileSectionItem(
                          iconName: 'straighten',
                          title: 'Nível de Atividade',
                          subtitle: _getActivityDisplayName(
                              _userProfile!.activityLevel),
                          onTap: () => _showOptionsSheet(
                            title: 'Selecionar nível',
                            options: const [
                              'Sedentário',
                              'Levemente Ativo',
                              'Moderadamente Ativo',
                              'Muito Ativo',
                              'Extremamente Ativo'
                            ],
                            currentValue: _getActivityDisplayName(
                                _userProfile!.activityLevel),
                            onSelected: (value) async {
                              String dbValue;
                              switch (value) {
                                case 'Sedentário':
                                  dbValue = 'sedentary';
                                  break;
                                case 'Levemente Ativo':
                                  dbValue = 'lightly_active';
                                  break;
                                case 'Moderadamente Ativo':
                                  dbValue = 'moderately_active';
                                  break;
                                case 'Muito Ativo':
                                  dbValue = 'very_active';
                                  break;
                                case 'Extremamente Ativo':
                                  dbValue = 'extremely_active';
                                  break;
                                default:
                                  dbValue = 'lightly_active';
                              }

                              try {
                                final updatedProfile = await UserService
                                    .instance
                                    .updateCurrentUserProfile(
                                    updates: {'activity_level': dbValue});
                                if (updatedProfile != null) {
                                  setState(() {
                                    _userProfile = updatedProfile;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao atualizar: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        ProfileSectionItem(
                          iconName: 'fitness_center',
                          title: 'Medidas Corporais',
                          subtitle: 'Altura, Peso, Percentual de Gordura',
                          onTap: _showMeasurementsDialog,
                        ),
                        ProfileSectionItem(
                          iconName: 'checklist_outlined', // Ícone de "checklist"
                          title: 'Refazer Onboarding',
                          subtitle: 'Atualizar suas preferências iniciais',
                          onTap: () {
                            // Navega para a tela de onboarding
                            // Certifique-se de que 'AppRoutes.onboardingScreen' é a rota correta
                            Navigator.pushNamed(context, AppRoutes.onboardingFlow);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'CONFIGURAÇÕES DO APP',
                      items: [
                        ProfileSectionItem(
                          iconName: 'notifications',
                          title: 'Notificação',
                          subtitle: _notificationsEnabled
                              ? 'Ativado'
                              : 'Desativado',

                          // ===== LÓGICA DO SWITCH ATUALIZADA =====
                          trailing: _isTogglingNotifications
                              ? const SizedBox(
                            width: 52, // Largura aprox. do Switch
                            height: 36, // Altura aprox. do Switch
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                          )
                              : Switch(
                            value: _notificationsEnabled,
                            onChanged: _toggleNotifications,
                            activeColor: AppTheme.accentGold,
                          ),
                          onTap: _isTogglingNotifications
                              ? null
                              : () => _toggleNotifications(!_notificationsEnabled),
                          // =======================================
                        ),
                        ProfileSectionItem(
                          iconName: 'sync',

                          // ===== TEXTO CORRIGIDO =====
                          title: 'Sincronização',
                          // ===========================

                          subtitle: _dataSyncEnabled ? 'Ativada' : 'Desativada',
                          trailing: Switch(
                            value: _dataSyncEnabled,
                            onChanged: (value) {
                              setState(() => _dataSyncEnabled = value);
                            },
                            activeColor: AppTheme.accentGold,
                          ),
                          onTap: () {
                            setState(
                                    () => _dataSyncEnabled = !_dataSyncEnabled);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'DADOS E COMPARTILHAMENTO',
                      items: [
                        ProfileSectionItem(
                          iconName: 'share',
                          title: 'Compartilhar Perfil',
                          subtitle: 'Compartilhe sua jornada fitness',
                          onTap: () async {
                            try {
                              final name = _userProfile!.fullName;
                              final goal = _getGoalDisplayName(
                                  _userProfile!.fitnessGoal);
                              final memberSince =
                              _formatDate(_userProfile!.createdAt);

                              await Share.share(
                                'Confira meu perfil do BLDR Fitness!\n\n'
                                    '👤 $name\n'
                                    '🎯 Objetivo: $goal\n'
                                    '📅 Membro desde: $memberSince\n\n'
                                    'Junte-se a mim no BLDR APP - Construa sua melhor versão!',
                                subject: 'Perfil BLDR APP de $name',
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                  Text('Erro ao compartilhar perfil: $e'),
                                  backgroundColor: AppTheme.errorRed,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ProfileSectionWidget(
                      title: 'CONTA',
                      items: [
                        ProfileSectionItem(
                          iconName: 'logout',
                          title: 'Sair',
                          subtitle: 'Sair da sua conta',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmationDialogWidget(
                                title: 'Sair',
                                message: 'Tem certeza que deseja sair?',
                                confirmText: 'Sair',
                                onConfirm: () async {
                                  try {
                                    await AuthService.instance.signOut();
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      AppRoutes.loginScreen,
                                          (route) => false,
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro ao sair: $e'),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          isDestructive: true,
                        ),
                        // NOVO ITEM PARA EXCLUIR CONTA
                        ProfileSectionItem(
                          iconName: 'delete',
                          title: 'Excluir Conta',
                          subtitle: 'Esta ação é permanente',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => ConfirmationDialogWidget(
                                title: 'Excluir Conta',
                                message: 'Tem certeza que deseja excluir sua conta?\n\nTodos os seus dados e sua assinatura serão removidos permanentemente. Esta ação não pode ser desfeita.',
                                confirmText: 'Sim, Excluir',
                                onConfirm: () async {
                                  try {
                                    await AuthService.instance.deleteUserAccount();

                                    // VERIFICAÇÃO DE SEGURANÇA ANTES DE USAR O CONTEXT
                                    if (!mounted) return;

                                    // Usamos o 'context' principal, não o do dialog, para a navegação
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.loginScreen,
                                          (route) => false,
                                    );
                                  } catch (e) {
                                    // VERIFICAÇÃO DE SEGURANÇA ANTES DE USAR O CONTEXT
                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro ao excluir conta: $e'),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
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