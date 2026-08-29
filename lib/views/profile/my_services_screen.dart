import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  // Track selected services & their prices locally
  // key = serviceId, value = price (null = selected but no price yet)
  final Map<String, double?> _selectedServices = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    await serviceProvider.fetchAdminServices();
    if (authProvider.user != null) {
      await serviceProvider.fetchVendorServices(authProvider.user!.uid);

      // Pre-fill selected services from vendor's existing services
      for (var vs in serviceProvider.vendorServices) {
        _selectedServices[vs.serviceId] = vs.price;
      }
      setState(() {});
    }
  }

  // Toggle selection
  void _toggleService(String serviceId, double? existingPrice) {
    setState(() {
      if (_selectedServices.containsKey(serviceId)) {
        _selectedServices.remove(serviceId);
      } else {
        _selectedServices[serviceId] = existingPrice;
      }
      _hasChanges = true;
    });
  }

  // Update price
  void _updatePrice(String serviceId, double price) {
    setState(() {
      _selectedServices[serviceId] = price;
      _hasChanges = true;
    });
  }

  // Save all selected services
  Future<void> _saveSelectedProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    if (authProvider.user == null) return;

    // Check if any selected service has no price
    bool hasMissingPrice = false;
    for (var entry in _selectedServices.entries) {
      if (entry.value == null || entry.value! <= 0) {
        hasMissingPrice = true;
        break;
      }
    }

    if (hasMissingPrice) {
      Helpers.showErrorToast('Please set price for all selected services');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final vendorId = authProvider.user!.uid;

      // Remove services that are deselected
      for (var vs in serviceProvider.vendorServices) {
        if (!_selectedServices.containsKey(vs.serviceId)) {
          await serviceProvider.removeService(
            vendorId: vendorId,
            serviceId: vs.serviceId,
          );
        }
      }

      // Add/update selected services
      for (var entry in _selectedServices.entries) {
        final existingService = serviceProvider.getVendorService(entry.key);
        final adminService = serviceProvider.adminServices.firstWhere(
          (s) => s.id == entry.key,
        );

        if (existingService == null) {
          // New service
          await serviceProvider.addService(
            vendorId: vendorId,
            service: adminService,
            price: entry.value!,
          );
        } else if (existingService.price != entry.value) {
          // Price updated
          await serviceProvider.updateServicePrice(
            vendorId: vendorId,
            serviceId: entry.key,
            newPrice: entry.value!,
          );
        }
      }

      if (mounted) Navigator.pop(context); // Close loading
      Helpers.showSuccessToast('Services saved successfully!');
      setState(() => _hasChanges = false);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Helpers.showErrorToast('Failed to save services');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, child) {
          if (serviceProvider.isLoading) {
            return const LoadingWidget(message: 'Loading services...');
          }

          if (serviceProvider.adminServices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.work_outline,
              title: 'No Services Available',
              message: 'Services will be added by admin soon.',
            );
          }

          final selectedCount = _selectedServices.length;

          return Column(
            children: [
              // ── Info Banner ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Select products to offer and set your own prices. These will appear in your services list.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected count
                    Text(
                      'Selected: $selectedCount products',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Services List
                    ...serviceProvider.adminServices.map((service) {
                      final isSelected = _selectedServices.containsKey(
                        service.id,
                      );
                      final currentPrice = _selectedServices[service.id];

                      return _ServiceCard(
                        service: service,
                        isSelected: isSelected,
                        currentPrice: currentPrice,
                        onToggle: () {
                          final existingVendorService = serviceProvider
                              .getVendorService(service.id);
                          _toggleService(
                            service.id,
                            existingVendorService?.price,
                          );
                        },
                        onPriceChanged: (price) {
                          _updatePrice(service.id, price);
                        },
                      );
                    }),
                  ],
                ),
              ),

              // ── Save Button ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                color: AppColors.background,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saveSelectedProducts,
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text(
                        'Save Selected Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SERVICE CARD — Exactly matching the image UI
// ═══════════════════════════════════════════════════════════════

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final double? currentPrice;
  final VoidCallback onToggle;
  final ValueChanged<double> onPriceChanged;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.currentPrice,
    required this.onToggle,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Checkbox ────────────────────────────────────────
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // ── Service Image ────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: service.imageUrl.isNotEmpty
                          ? Image.network(
                              service.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  service.displayIcon,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                service.displayIcon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Service Name ─────────────────────────────────────
                  Expanded(
                    child: Text(
                      service.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Price Input (only when selected) ─────────────────────
              if (isSelected) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Your Price',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PriceInputField(
                        initialPrice: currentPrice,
                        onPriceChanged: onPriceChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRICE INPUT FIELD
// ═══════════════════════════════════════════════════════════════

class _PriceInputField extends StatefulWidget {
  final double? initialPrice;
  final ValueChanged<double> onPriceChanged;

  const _PriceInputField({
    required this.initialPrice,
    required this.onPriceChanged,
  });

  @override
  State<_PriceInputField> createState() => _PriceInputFieldState();
}

class _PriceInputFieldState extends State<_PriceInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPrice != null
          ? widget.initialPrice!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Prevent card toggle when tapping input
      onTap: () {},
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          final price = double.tryParse(value);
          if (price != null && price > 0) {
            widget.onPriceChanged(price);
          }
        },
        decoration: InputDecoration(
          hintText: 'Enter price',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Text(
              '₹',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
