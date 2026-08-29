// lib/views/orders/widgets/rating_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../core/utils/app_navigator.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/customer_review_provider.dart';

class RatingDialog extends StatefulWidget {
  final OrderModel order;

  const RatingDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final dialogContext = AppNavigator.context;
    if (dialogContext == null) {
      debugPrint('RatingDialog: No context available');
      return;
    }

    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      // ✅ Use this to handle keyboard
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider(
        create: (_) => CustomerReviewProvider(),
        child: RatingDialog(order: order),
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog>
    with SingleTickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating == 0) return 'Tap to rate';
    if (_rating == 1) return 'Poor 😕';
    if (_rating == 2) return 'Fair 🙂';
    if (_rating == 3) return 'Good 👍';
    if (_rating == 4) return 'Very Good 😊';
    return 'Excellent! 🌟';
  }

  Color get _ratingColor {
    if (_rating == 0) return AppColors.textHint;
    if (_rating <= 2) return AppColors.error;
    if (_rating <= 3) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _submit() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<CustomerReviewProvider>();

    final success = await provider.submitReview(
      orderId: widget.order.orderId,
      customerId: widget.order.customerId,
      customerName: widget.order.customerName,
      vendorId: widget.order.vendorId,
      rating: _rating,
      review: _reviewController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSuccessSnack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to submit review'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnack() {
    final ctx = AppNavigator.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Review submitted! Thanks 🎉'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get keyboard height to adjust padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Order completed banner
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Order Completed! 🎉',
                        style: AppTextStyles.heading5.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rate your experience with',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.order.customerName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5 Stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1.0;
                          return GestureDetector(
                            onTap: () => setState(() => _rating = starValue),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                _rating >= starValue
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: _rating >= starValue
                                    ? Colors.amber
                                    : AppColors.grey300,
                                size: _rating >= starValue ? 44 : 38,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),

                      // Rating label
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _ratingLabel,
                          key: ValueKey(_rating),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _ratingColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Review text box
                      TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        maxLength: 300,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'Write a review (optional)...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          counterStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      Consumer<CustomerReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          return Row(
                            children: [
                              // Skip button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: reviewProvider.isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Skip',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Submit button
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: reviewProvider.isSubmitting
                                      ? null
                                      : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: reviewProvider.isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Submit Review',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
