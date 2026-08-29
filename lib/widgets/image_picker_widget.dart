import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../config/app_config.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isLoading;
  final String? error;

  const ImagePickerWidget({
    super.key,
    this.imageFile,
    required this.label,
    required this.hint,
    required this.onTap,
    this.onRemove,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Image Container
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: error != null ? AppColors.error : AppColors.border,
                width: error != null ? 2 : 1,
              ),
            ),
            child: isLoading
                ? _buildLoading()
                : imageFile != null
                ? _buildImagePreview()
                : _buildPlaceholder(),
          ),
        ),

        // Error Text
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hint,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to upload',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
          child: Image.file(imageFile!, fit: BoxFit.cover),
        ),

        // Overlay with actions
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              // Edit Button
              _buildActionButton(
                icon: Icons.edit,
                onTap: onTap,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              // Remove Button
              if (onRemove != null)
                _buildActionButton(
                  icon: Icons.close,
                  onTap: onRemove!,
                  color: AppColors.error,
                ),
            ],
          ),
        ),

        // Success indicator
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Selected',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Processing...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMAGE PICKER HELPER - UPDATED WITH COMPRESSION
// ═══════════════════════════════════════════════════════════════
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Initial quality
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        // Compress the image
        return await _compressImage(File(pickedFile.path));
      }
      return null;
    } catch (e) {
      debugPrint('Image picker error: $e');
      return null;
    }
  }

  static Future<File?> _compressImage(File file) async {
    try {
      debugPrint('📸 ====== Image Compression Started ======');
      debugPrint(
        '📸 Original size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
      );

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: AppConfig.imageQuality, // e.g., 70
        minWidth: 800,
        minHeight: 800,
      );

      if (result != null) {
        debugPrint(
          '✅ Compressed size: ${(File(result.path).lengthSync() / 1024).toStringAsFixed(2)} KB',
        );
        debugPrint('📸 ====== Image Compression Finished ======');
        return File(result.path);
      } else {
        debugPrint('⚠️ Compression returned null. Using original file.');
        debugPrint('📸 ====== Image Compression Failed ======');
        return file; // Return original if compression fails
      }
    } catch (e) {
      debugPrint('❌ Image compression error: $e');
      debugPrint('📸 ====== Image Compression Failed ======');
      return file; // Return original file on error
    }
  }

  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<File>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSourceOption(
                  context: context,
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  subtitle: 'Take a new photo',
                  onTap: () async {
                    final file = await pickImage(source: ImageSource.camera);
                    Navigator.pop(context, file);
                  },
                ),
                const SizedBox(height: 12),
                _buildSourceOption(
                  context: context,
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  subtitle: 'Choose from gallery',
                  onTap: () async {
                    final file = await pickImage(source: ImageSource.gallery);
                    Navigator.pop(context, file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
