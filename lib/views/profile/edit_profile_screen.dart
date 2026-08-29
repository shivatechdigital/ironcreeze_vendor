import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/image_picker_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _contactController = TextEditingController();

  File? _newProfileImage;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final vendor = Provider.of<VendorProvider>(context, listen: false).vendor;
    if (vendor != null) {
      _nameController.text = vendor.name;
      _shopNameController.text = vendor.shopName;
      _addressController.text = vendor.address;
      _cityController.text = vendor.city;
      _pinCodeController.text = vendor.pinCode;
      _contactController.text = vendor.contactNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickProfileImage() async {
    final file = await ImagePickerHelper.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _newProfileImage = file;
        _hasChanges = true;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    Helpers.hideKeyboard(context);

    setState(() => _isLoading = true);

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    try {
      // Upload new profile image if selected
      String? newImageUrl;
      if (_newProfileImage != null) {
        setState(() => _isUploadingImage = true);
        newImageUrl = await vendorProvider.uploadProfileImage(
          _newProfileImage!,
        );
        setState(() => _isUploadingImage = false);
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'contactNumber': _contactController.text.trim(),
      };

      if (newImageUrl != null) {
        updateData['profileImage'] = newImageUrl;
      }

      final success = await vendorProvider.updateVendor(updateData);

      if (success && mounted) {
        Helpers.showSuccessToast('Profile updated successfully!');
        Navigator.pop(context);
      } else {
        Helpers.showErrorToast(
          vendorProvider.error ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      debugPrint('Save profile error: $e');
      Helpers.showErrorToast('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldPop = await _showDiscardDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Edit Profile',
          showBackButton: true,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _handleSave,
                child: Text(
                  'Save',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<VendorProvider>(
          builder: (context, vendorProvider, child) {
            final vendor = vendorProvider.vendor;

            if (vendor == null) {
              return const Center(child: Text('No vendor data'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image
                    _buildProfileImageSection(vendor.profileImage),

                    const SizedBox(height: 32),

                    // Personal Details Section
                    _buildSectionTitle('Personal Details'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.validateName,
                      onChanged: (_) => _onFieldChanged(),
                    ),

                    const SizedBox(height: 32),

                    // Shop Details Section
                    _buildSectionTitle('Shop Details'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _shopNameController,
                      label: 'Shop Name',
                      hint: 'Enter shop name',
                      prefixIcon: Icons.store_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.validateShopName,
                      onChanged: (_) => _onFieldChanged(),
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter complete address',
                      prefixIcon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      validator: Validators.validateAddress,
                      onChanged: (_) => _onFieldChanged(),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                            prefixIcon: Icons.location_city_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: Validators.validateCity,
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _pinCodeController,
                            label: 'Pin Code',
                            hint: '6 digits',
                            prefixIcon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.validatePinCode,
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _contactController,
                      label: 'Contact Number',
                      hint: 'Enter contact number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: Validators.validatePhone,
                      onChanged: (_) => _onFieldChanged(),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _hasChanges ? _handleSave : null,
                      isLoading: _isLoading,
                      isDisabled: !_hasChanges,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(String? currentImageUrl) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipOval(
                child: _newProfileImage != null
                    ? Image.file(_newProfileImage!, fit: BoxFit.cover)
                    : currentImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: currentImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppColors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final vendor = Provider.of<VendorProvider>(context, listen: false).vendor;
    return Container(
      color: AppColors.primaryBackground,
      child: Center(
        child: Text(
          Helpers.getInitials(vendor?.name ?? ''),
          style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.heading6.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard Changes?', style: AppTextStyles.heading6),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
