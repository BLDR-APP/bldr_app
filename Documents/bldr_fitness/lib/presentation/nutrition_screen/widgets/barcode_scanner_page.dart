import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    final Barcode? barcode = barcodes.isNotEmpty ? barcodes.first : null;

    if (barcode != null && barcode.rawValue != null) {
      setState(() {
        _isScanned = true;
      });

      Navigator.pop(context, barcode.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text(
          'Escanear Código',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.textPrimary,
            size: 6.w,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppTheme.accentGold,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withAlpha(230),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'qr_code_scanner',
                    color: AppTheme.accentGold,
                    size: 8.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Aponte a câmera para o código de barras',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'O código será detectado automaticamente',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  'flash_on',
                  'Flash',
                  () => cameraController.toggleTorch(),
                ),
                _buildControlButton(
                  'flip_camera_ios',
                  'Câmera',
                  () => cameraController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withAlpha(204),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.textPrimary,
              size: 4.w,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path center = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, center);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final centerWidth = cutOutSize / 2 + borderOffset;
    final centerHeight = cutOutSize / 2 + borderOffset;

    final centerX = width / 2;
    final centerY = height / 2;

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(centerX - centerWidth, centerY - centerHeight + borderRadius)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX - centerWidth + borderRadius,
                centerY - centerHeight + borderRadius),
            radius: borderRadius,
          ),
          180 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        )
        ..lineTo(centerX - centerWidth + borderLength, centerY - centerHeight),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(centerX - centerWidth + borderRadius, centerY - centerHeight)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX - centerWidth + borderRadius,
                centerY - centerHeight + borderRadius),
            radius: borderRadius,
          ),
          270 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        )
        ..lineTo(centerX - centerWidth, centerY - centerHeight + borderLength),
      borderPaint,
    );

    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(centerX + centerWidth - borderLength, centerY - centerHeight)
        ..lineTo(centerX + centerWidth - borderRadius, centerY - centerHeight)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX + centerWidth - borderRadius,
                centerY - centerHeight + borderRadius),
            radius: borderRadius,
          ),
          270 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(centerX + centerWidth, centerY - centerHeight + borderLength)
        ..lineTo(centerX + centerWidth, centerY - centerHeight + borderRadius)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX + centerWidth - borderRadius,
                centerY - centerHeight + borderRadius),
            radius: borderRadius,
          ),
          0 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );

    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(centerX - centerWidth, centerY + centerHeight - borderLength)
        ..lineTo(centerX - centerWidth, centerY + centerHeight - borderRadius)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX - centerWidth + borderRadius,
                centerY + centerHeight - borderRadius),
            radius: borderRadius,
          ),
          180 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(centerX - centerWidth + borderLength, centerY + centerHeight)
        ..lineTo(centerX - centerWidth + borderRadius, centerY + centerHeight)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX - centerWidth + borderRadius,
                centerY + centerHeight - borderRadius),
            radius: borderRadius,
          ),
          90 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );

    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(centerX + centerWidth - borderRadius, centerY + centerHeight)
        ..lineTo(centerX + centerWidth - borderLength, centerY + centerHeight)
        ..moveTo(centerX + centerWidth, centerY + centerHeight - borderRadius)
        ..lineTo(centerX + centerWidth, centerY + centerHeight - borderLength),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(centerX + centerWidth - borderLength, centerY + centerHeight)
        ..lineTo(centerX + centerWidth - borderRadius, centerY + centerHeight)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX + centerWidth - borderRadius,
                centerY + centerHeight - borderRadius),
            radius: borderRadius,
          ),
          90 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(centerX + centerWidth, centerY + centerHeight - borderLength)
        ..lineTo(centerX + centerWidth, centerY + centerHeight - borderRadius)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(centerX + centerWidth - borderRadius,
                centerY + centerHeight - borderRadius),
            radius: borderRadius,
          ),
          0 * (3.14159 / 180),
          90 * (3.14159 / 180),
          false,
        ),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
