import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../data/models/vendor_model.dart';
import '../../core/enums/auth_type.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class VendorProfileScreen extends StatefulWidget {
  final String? email;
  final String? phone;
  final String? authType;

  const VendorProfileScreen({super.key, this.email, this.phone, this.authType});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _contactController = TextEditingController();

  // Profile Picture
  File? _profilePictureFile;

  // Aadhar Documents
  File? _aadharFrontFile;
  File? _aadharBackFile;

  bool _isSubmitting = false;
  String? _aadharFrontError;
  String? _aadharBackError;

  // Store auth type persistently
  String? _storedAuthType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    // Load stored auth type from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get auth type: priority is (1) stored value, (2) widget param, (3) null
    String? authType = prefs.getString(
      'user_auth_type_${authProvider.user?.uid}',
    );

    if (authType == null && widget.authType != null) {
      authType = widget.authType;
      // Store it for future
      await prefs.setString(
        'user_auth_type_${authProvider.user?.uid}',
        authType!,
      );
    }

    // Pre-fill email or phone from auth
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
    if (widget.phone != null && widget.phone!.isNotEmpty) {
      _phoneController.text = widget.phone!;
      _contactController.text = widget.phone!;
    }

    // Get user info from auth provider
    if (authProvider.user != null) {
      if (_emailController.text.isEmpty && authProvider.userEmail != null) {
        _emailController.text = authProvider.userEmail!;
      }
      if (_nameController.text.isEmpty &&
          authProvider.userDisplayName != null) {
        _nameController.text = authProvider.userDisplayName!;
      }
    }

    setState(() {
      _storedAuthType = authType;
      _isLoading = false;
    });

    debugPrint('✅ Stored Auth Type: $_storedAuthType');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Profile Picture'),
        content: const Text('Choose from where you want to pick the image'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('camera', 'profile');
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('gallery', 'profile');
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _removeProfilePicture() {
    setState(() {
      _profilePictureFile = null;
    });
  }

  Future<void> _pickAadharFront() async {
    setState(() {
      _aadharFrontError = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Image Source'),
        content: const Text('Choose from where you want to pick the image'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('camera', 'front');
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('gallery', 'front');
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAadharBack() async {
    setState(() {
      _aadharBackError = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Image Source'),
        content: const Text('Choose from where you want to pick the image'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('camera', 'back');
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromSource('gallery', 'back');
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromSource(String source, String type) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick image from camera or gallery
      final XFile? image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        File file = File(image.path);

        final processed = await _cropAndCompressImage(
          file,
          type: type == 'profile' ? 'profile' : 'aadhar',
        );

        if (processed != null) {
          file = processed;
        }

        setState(() {
          if (type == 'profile') {
            _profilePictureFile = file;
          } else if (type == 'front') {
            _aadharFrontFile = file;
          } else if (type == 'back') {
            _aadharBackFile = file;
          }
        });

        Helpers.showSuccessToast("Image ready for upload");
      } else {
        Helpers.showErrorToast('No image selected. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      Helpers.showErrorToast('Failed to pick image. Please try again.');
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

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter your name');
      return false;
    }
    if (_shopNameController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter shop name');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter address');
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter city');
      return false;
    }
    if (_stateController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter state');
      return false;
    }
    if (_pinCodeController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter pin code');
      return false;
    }
    if (_contactController.text.trim().isEmpty) {
      Helpers.showErrorToast('Please enter contact number');
      return false;
    }
    if (_aadharFrontFile == null) {
      setState(() {
        _aadharFrontError = 'Please upload Aadhar front';
      });
      return false;
    }
    if (_aadharBackFile == null) {
      setState(() {
        _aadharBackError = 'Please upload Aadhar back';
      });
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

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
      final aadharFrontUrl = await vendorProvider.uploadDocument(
        _aadharFrontFile!,
        'aadhar_front',
      );
      if (aadharFrontUrl == null) {
        throw Exception('Failed to upload Aadhar front.');
      }

      // Upload Aadhar Back
      final aadharBackUrl = await vendorProvider.uploadDocument(
        _aadharBackFile!,
        'aadhar_back',
      );
      if (aadharBackUrl == null) {
        throw Exception('Failed to upload Aadhar back.');
      }

      // Upload Profile Picture if provided
      String? profilePictureUrl;
      if (_profilePictureFile != null) {
        profilePictureUrl = await vendorProvider.uploadDocument(
          _profilePictureFile!,
          'profile_picture',
        );
      }

      // Create Vendor Model
      final vendor = VendorModel(
        uid: authProvider.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        authType: AuthType.fromString(_storedAuthType ?? 'email'),
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        contactNumber: _contactController.text.trim(),
        profilePicture: profilePictureUrl,
        aadharFront: aadharFrontUrl,
        aadharBack: aadharBackUrl,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final success = await vendorProvider.createVendor(vendor);

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
      if (mounted) Navigator.pop(context);
      Helpers.showErrorToast(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit Registration?', style: AppTextStyles.heading6),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
              AppRoutes.navigateAndClearStack(context, AppRoutes.login);
            },
            child: Text(
              'Exit',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<File?> _cropAndCompressImage(File file, {required String type}) async {
    /// Fixed aspect ratio
    CropAspectRatio ratio;

    if (type == 'profile') {
      ratio = const CropAspectRatio(ratioX: 1, ratioY: 1);
    } else {
      // Aadhaar card ratio
      ratio = const CropAspectRatio(ratioX: 16, ratioY: 10);
    }

    /// Crop image
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: ratio,

      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.orange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),

        IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
      ],
    );

    if (cropped == null) return null;

    /// Compress image
    final compressedPath = "${cropped.path}_compressed.jpg";

    final compressed = await FlutterImageCompress.compressAndGetFile(
      cropped.path,
      compressedPath,

      quality: 85,

      /// Fixed size for Aadhaar
      minWidth: type == 'profile' ? 500 : 1000,
      minHeight: type == 'profile' ? 500 : 600,
    );

    if (compressed == null) return null;

    return File(compressed.path);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Create Vendor Profile',
          showBackButton: true,
          onBackPressed: _showExitConfirmation,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========= PROFILE PICTURE SECTION =========
                  _buildProfilePictureSection(),
                  const SizedBox(height: 32),

                  // ========= BUSINESS DETAILS =========
                  Text(
                    'Business Name',
                    style: AppTextStyles.heading6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _shopNameController,
                    label: 'Business Name',
                    hint: 'Enter business name',
                    prefixIcon: Icons.store_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateShopName,
                  ),
                  const SizedBox(height: 16),

                  // ========= PERSONAL DETAILS =========
                  Text(
                    'Owner Details',
                    style: AppTextStyles.heading6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _nameController,
                    label: 'Owner Name',
                    hint: 'Enter your name',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),

                  // Email Field - Check stored auth type
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled:
                        _storedAuthType != 'email' &&
                        _storedAuthType != 'google',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return Validators.validateEmail(value);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field - Check stored auth type
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    textInputAction: TextInputAction.next,
                    enabled: _storedAuthType != 'phone',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return Validators.validatePhone(value);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ========= BUSINESS ADDRESS =========
                  Text(
                    'Business Address',
                    style: AppTextStyles.heading6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _addressController,
                    label: 'Enter Full Address',
                    hint: 'Enter Full Address',
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    validator: Validators.validateAddress,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'City',
                    prefixIcon: Icons.location_city_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateCity,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'State',
                    prefixIcon: Icons.map_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _pinCodeController,
                    label: 'Enter Pincode',
                    hint: 'Pincode',
                    prefixIcon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.validatePinCode,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _contactController,
                    label: 'Contact Number',
                    hint: 'Shop contact number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 24),

                  // ========= AADHAR UPLOAD SECTION =========
                  Text(
                    'Upload Aadhar Card',
                    style: AppTextStyles.heading6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildAadharUploadBox(
                          'Front Side',
                          _aadharFrontFile,
                          _pickAadharFront,
                          _aadharFrontFile != null ? _removeAadharFront : null,
                          _aadharFrontError,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAadharUploadBox(
                          'Back Side',
                          _aadharBackFile,
                          _pickAadharBack,
                          _aadharBackFile != null ? _removeAadharBack : null,
                          _aadharBackError,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ========= SUBMIT BUTTON =========
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: CustomButton(
                      text: 'Create Profile',
                      onPressed: _handleSubmit,
                      isLoading: _isSubmitting,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE8730F),
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                ).signOut();
                                AppRoutes.navigateAndClearStack(
                                  context,
                                  AppRoutes.login,
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickProfilePicture,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE8730F),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(70),
                color: const Color(0xFFFFF3E0),
              ),
              child: _profilePictureFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: Image.file(
                        _profilePictureFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFFE8730F),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Profile Picture',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_profilePictureFile != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _removeProfilePicture,
            child: Text(
              'Remove',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAadharUploadBox(
    String label,
    File? file,
    VoidCallback onTap,
    VoidCallback? onRemove,
    String? error,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? Colors.red : const Color(0xFFE8730F),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFF3E0),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFE8730F),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFE8730F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRemove,
            child: Text(
              'Remove',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
