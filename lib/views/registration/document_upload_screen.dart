import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/enums/auth_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../data/models/vendor_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/image_picker_widget.dart';
import '../../routes/app_routes.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? _aadharFrontFile;
  File? _aadharBackFile;

  final bool _isUploading = false;
  bool _isSubmitting = false;

  String? _aadharFrontError;
  String? _aadharBackError;

  Map<String, dynamic>? _vendorData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get data from previous screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _vendorData = args;
    }
  }

  Future<void> _pickAadharFront() async {
    setState(() {
      _aadharFrontError = null;
    });

    final file = await ImagePickerHelper.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _aadharFrontFile = file;
      });
    }
  }

  Future<void> _pickAadharBack() async {
    setState(() {
      _aadharBackError = null;
    });

    final file = await ImagePickerHelper.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _aadharBackFile = file;
      });
    }
  }

  void _removeAadharFront() {
    setState(() {
      _aadharFrontFile = null;
    });
  }

  void _removeAadharBack() {
    setState(() {
      _aadharBackFile = null;
    });
  }

  bool _validateDocuments() {
    bool isValid = true;

    if (_aadharFrontFile == null) {
      setState(() {
        _aadharFrontError = 'Please upload Aadhar card front';
      });
      isValid = false;
    }

    if (_aadharBackFile == null) {
      setState(() {
        _aadharBackError = 'Please upload Aadhar card back';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateDocuments()) return;
    if (_vendorData == null) {
      Helpers.showErrorToast('Missing vendor information. Please go back.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Show a full-screen loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.white),
              SizedBox(height: 16),
              Text(
                'Submitting Registration...',
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final vendorProvider = Provider.of<VendorProvider>(
        context,
        listen: false,
      );

      if (authProvider.user == null) {
        throw Exception('Session expired. Please login again.');
      }

      // Upload Aadhar Front
      debugPrint('📤 Uploading Aadhar Front...');
      final aadharFrontUrl = await vendorProvider.uploadDocument(
        _aadharFrontFile!,
        'aadhar_front',
      );
      if (aadharFrontUrl == null) {
        throw Exception('Failed to upload Aadhar front.');
      }

      // Upload Aadhar Back
      debugPrint('📤 Uploading Aadhar Back...');
      final aadharBackUrl = await vendorProvider.uploadDocument(
        _aadharBackFile!,
        'aadhar_back',
      );
      if (aadharBackUrl == null) {
        throw Exception('Failed to upload Aadhar back.');
      }

      // Create Vendor Model
      final vendor = VendorModel(
        uid: authProvider.user!.uid,
        name: _vendorData!['name'],
        email: _vendorData!['email'] ?? '',
        phone: _vendorData!['phone'] ?? '',
        authType: AuthType.fromString(_vendorData!['authType'] ?? 'email'),
        shopName: _vendorData!['shopName'],
        address: _vendorData!['address'],
        city: _vendorData!['city'],
        pinCode: _vendorData!['pinCode'],
        contactNumber: _vendorData!['contactNumber'],
        aadharFront: aadharFrontUrl,
        aadharBack: aadharBackUrl,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      debugPrint('💾 Saving vendor to Firestore...');
      final success = await vendorProvider.createVendor(vendor);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        Helpers.showSuccessToast('Registration submitted successfully!');
        if (mounted) {
          AppRoutes.navigateAndClearStack(context, AppRoutes.pendingApproval);
        }
      } else {
        Helpers.showErrorToast(
          vendorProvider.error ?? 'Failed to submit registration.',
        );
      }
    } catch (e) {
      debugPrint('❌ Submit error: $e');
      if (mounted) Navigator.pop(context); // Close loading dialog on error
      Helpers.showErrorToast(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Upload Documents', showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Identity Verification',
                      style: AppTextStyles.heading4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your Aadhar card for verification',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Aadhar Front
                    ImagePickerWidget(
                      imageFile: _aadharFrontFile,
                      label: 'Aadhar Card - Front Side *',
                      hint: 'Upload front side of Aadhar',
                      onTap: _pickAadharFront,
                      onRemove: _aadharFrontFile != null
                          ? _removeAadharFront
                          : null,
                      error: _aadharFrontError,
                    ),
                    const SizedBox(height: 24),

                    // Aadhar Back
                    ImagePickerWidget(
                      imageFile: _aadharBackFile,
                      label: 'Aadhar Card - Back Side *',
                      hint: 'Upload back side of Aadhar',
                      onTap: _pickAadharBack,
                      onRemove: _aadharBackFile != null
                          ? _removeAadharBack
                          : null,
                      error: _aadharBackError,
                    ),

                    // Guidelines
                    const SizedBox(height: 32),
                    _buildGuidelines(),
                  ],
                ),
              ),
            ),

            // Bottom Button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, 'Personal', true),
          _buildStepLine(true),
          _buildStepDot(1, 'Shop', true),
          _buildStepLine(true),
          _buildStepDot(2, 'Documents', false),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label, bool isCompleted) {
    final isActive = step == 2;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.grey200,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: AppColors.primary, width: 3)
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : Text(
                      '${step + 1}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isActive ? AppColors.white : AppColors.grey500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.grey500,
              fontWeight: isCompleted || isActive
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppColors.primary : AppColors.grey200,
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Document Guidelines',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem('Ensure the document is clearly visible'),
          _buildGuidelineItem('All four corners should be visible'),
          _buildGuidelineItem('Avoid blur or glare on the image'),
          _buildGuidelineItem('File size should be less than 5MB'),
          _buildGuidelineItem('Supported formats: JPG, PNG'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: CustomButton(
        text: 'Submit for Verification',
        onPressed: _handleSubmit,
        isLoading: _isSubmitting,
        prefixIcon: Icons.verified_outlined,
      ),
    );
  }
}
