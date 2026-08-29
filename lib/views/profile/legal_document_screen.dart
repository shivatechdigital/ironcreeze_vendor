import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

enum LegalDocument { terms, privacy }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocument.privacy;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms & Conditions';
    final sections = isPrivacy ? _privacySections : _termsSections;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.$1, style: AppTextStyles.heading6),
              const SizedBox(height: 8),
              Text(
                section.$2,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _termsSections = [
    (
      'Use of Service',
      'Use the IronCreeze Partner app only to manage your registered business, services, orders, and earnings.'
    ),
    (
      'Orders and Payments',
      'Keep services, prices, availability, order status, and payment records accurate. Complete collections and deliveries only through the order workflow.'
    ),
    (
      'Vendor Responsibilities',
      'You are responsible for lawful operation of your business, the quality of your services, and handling customer items with appropriate care.'
    ),
    (
      'Account Changes',
      'We may update these terms when required. Continued use after an update indicates acceptance of the revised terms.'
    ),
  ];

  static const _privacySections = [
    (
      'Information We Collect',
      'We collect business profile information, contact details, service prices, order information, device notification tokens, and documents submitted for vendor verification.'
    ),
    (
      'How We Use Information',
      'We use this information to verify vendors, connect you with customer orders, process payments, provide notifications, and operate the service.'
    ),
    (
      'Information Sharing',
      'Customer information is shared only as needed to fulfill orders. We use Firebase and service providers that support app operations.'
    ),
    (
      'Your Choices',
      'You can update your profile, control notifications in device settings, and permanently delete your account from the Profile screen.'
    ),
    ('Contact', 'For privacy questions, contact privacy@ironcreeze.com.'),
  ];
}