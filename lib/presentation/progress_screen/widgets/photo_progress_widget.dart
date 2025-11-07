import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// --- INÍCIO DA CORREÇÃO ---
// Importa o permission_handler
import 'package:permission_handler/permission_handler.dart';
// --- FIM DA CORREÇÃO ---

import '../../../core/app_export.dart';

class PhotoProgressWidget extends StatefulWidget {
  const PhotoProgressWidget({Key? key}) : super(key: key);

  @override
  State<PhotoProgressWidget> createState() => _PhotoProgressWidgetState();
}

class _PhotoProgressWidgetState extends State<PhotoProgressWidget> {
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _progressPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressPhotos();
  }

  Future<void> _loadProgressPhotos() async {
    setState(() => _isLoading = true);

    try {
      // In a real implementation, this would load from Supabase storage
      // For now, we'll use mock data
      await Future.delayed(const Duration(milliseconds: 500));

      final mockPhotos = [
        {
          'id': '1',
          'url':
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=300&h=400&fit=crop',
          'date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'type': 'front',
          'notes': 'Starting progress photo',
          'local': false,
        },
        {
          'id': '2',
          'url':
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=400&fit=crop',
          'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'type': 'side',
          'notes': '2 weeks progress',
          'local': false,
        },
      ];

      if (mounted) {
        setState(() {
          _progressPhotos = mockPhotos;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddPhotoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              'Adicionar foto de progresso',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoOption(
                    'Câmera',
                    'photo_camera',
                    AppTheme.accentGold,
                        () => _takePhoto(),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildPhotoOption(
                    'Galeria',
                    'photo_library',
                    AppTheme.successGreen,
                        () => _selectFromGallery(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
      String title,
      String iconName,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 6.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- INÍCIO DA CORREÇÃO (Lógica de Permissão) ---

  Future<void> _takePhoto() async {
    try {
      // 1. Solicita a permissão da Câmera
      final status = await Permission.camera.request();

      if (status.isGranted) {
        // 2. Se permitiu, abre a câmera
        final XFile? shot = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 95,
        );
        if (shot == null) return;
        final file = await _saveCompressed(File(shot.path));
        _addPhotoEntry(file, notes: 'Foto tirada com câmera');
      } else if (status.isPermanentlyDenied) {
        // 3. Se negou permanentemente, informa o usuário
        _showPermissionDeniedDialog(
            'Você negou permanentemente a permissão de câmera. Por favor, habilite nas configurações do app.');
      } else {
        // 4. Se apenas negou desta vez
        _toast('Permissão de câmera é necessária para tirar fotos.');
      }
    } catch (e) {
      _toast('Falha ao abrir a câmera: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      // 1. Solicita a permissão da Galeria
      // (Permission.photos é o moderno, Permission.storage é o antigo)
      final status = await Permission.photos.request();

      if (status.isGranted) {
        // 2. Se permitiu, abre a galeria
        final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
        );
        if (picked == null) return;
        final file = await _saveCompressed(File(picked.path));
        _addPhotoEntry(file, notes: 'Importada da galeria');
      } else if (status.isPermanentlyDenied) {
        // 3. Se negou permanentemente
        _showPermissionDeniedDialog(
            'Você negou permanentemente a permissão da galeria. Por favor, habilite nas configurações do app.');
      } else {
        // 4. Se apenas negou desta vez
        _toast('Permissão da galeria é necessária para escolher fotos.');
      }
    } catch (e) {
      _toast('Falha ao abrir a galeria: $e');
    }
  }

  // Helper para lidar com permissões negadas permanentemente
  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: Text(
          'Permissão Necessária',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(message, style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Abre as configurações do app
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  // --- FIM DA CORREÇÃO ---

  Future<File> _saveCompressed(File original) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath =
        '${dir.path}/bldr_progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      original.path,
      outPath,
      quality: 80,
      minWidth: 1080,
      minHeight: 1440,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
  }

  void _addPhotoEntry(File file, {String? notes}) {
    final now = DateTime.now().toIso8601String();
    setState(() {
      _progressPhotos.insert(0, {
        'id': now,
        'url': file.path, // local path
        'date': now,
        'type': 'front',
        'notes': notes ?? '',
        'local': true,
      });
    });
    _toast('Foto adicionada!');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.warningAmber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPhotoComparison() {
    if (_progressPhotos.length < 2) {
      _toast('Adicione ao menos 2 fotos para comparar progresso');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comparação do Progresso',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Antes',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: _imageProviderFor(_progressPhotos.last), // Correção: Antes é o último (mais antigo)
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _formatDate(_progressPhotos.last['date']),
                          style:
                          AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Depois',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: _imageProviderFor(_progressPhotos.first), // Correção: Depois é o primeiro (mais novo)
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _formatDate(_progressPhotos.first['date']),
                          style:
                          AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    return DateFormat('d/M/y').format(d);
  }

  ImageProvider _imageProviderFor(Map<String, dynamic> photo) {
    final isLocal =
        (photo['local'] == true) || (Uri.tryParse(photo['url'])?.isScheme('file') == true);
    return isLocal
        ? FileImage(File(photo['url']))
        : NetworkImage(photo['url']);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'photo_camera',
                  color: AppTheme.successGreen,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Foto do Progresso',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showAddPhotoDialog,
                icon: Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.successGreen,
                    size: 4.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppTheme.successGreen),
            )
          else if (_progressPhotos.isEmpty)
            _buildEmptyState()
          else
            _buildPhotoGallery(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          CustomIconWidget(
            iconName: 'photo_camera',
            color: AppTheme.inactiveGray,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Sem fotos ainda',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tire fotos para visualmente acompanhar sua transformação',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _showAddPhotoDialog,
            icon: Icon(Icons.add_a_photo, size: 5.w),
            label: const Text('Adicionar primeira foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final canCompare = _progressPhotos.length >= 2;

    return Column(
      children: [
        if (_progressPhotos.length >= 2) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canCompare ? _showPhotoComparison : null,
              icon: Icon(Icons.compare, size: 5.w),
              label: const Text('Comparar progresso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryBlack,
                disabledBackgroundColor: AppTheme.accentGold.withOpacity(0.4),
                disabledForegroundColor: AppTheme.primaryBlack.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(height: 3.h),
        ],
        SizedBox(
          height: 30.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _progressPhotos.length,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemBuilder: (context, index) {
              final photo = _progressPhotos[index];
              return _buildPhotoCard(photo, index);
            },
          ),
        ),
        SizedBox(height: 3.h),
        _buildPhotoTips(),
      ],
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo, int index) {
    final notes = photo['notes'] ?? '';

    return Container(
      width: 35.w,
      margin: EdgeInsets.only(right: 3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _viewPhoto(photo),
              onLongPress: () => _confirmDelete(photo),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: _imageProviderFor(photo),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2.w,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlack.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: AppTheme.darkTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2.w,
                        left: 2.w,
                        right: 2.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(photo['date']),
                              style: AppTheme.darkTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (notes.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                notes,
                                style: AppTheme.darkTheme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(Map<String, dynamic> photo) {
    final provider = _imageProviderFor(photo);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        insetPadding: EdgeInsets.all(4.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image(image: provider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Remover foto?'),
        content: const Text('Isso não pode ser desfeito.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _progressPhotos.removeWhere((p) => p['id'] == photo['id']));
    }
  }

  Widget _buildPhotoTips() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: AppTheme.warningAmber,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Dicas',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '• Tire fotos na mesma luz e pose\n'
                '• Utilize roupas similiares para consistência\n'
                '• Tire de frente, lado e de costas\n'
                '• Programe fotos semanais',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}