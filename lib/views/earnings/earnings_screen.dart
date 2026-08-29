import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../data/models/order_model.dart';
import '../../routes/app_routes.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String get _vendorId =>
      Provider.of<VendorProvider>(context, listen: false).vendor?.uid ?? '';

  void _loadData() {
    if (_vendorId.isNotEmpty) {
      Provider.of<EarningsProvider>(
        context,
        listen: false,
      ).fetchEarningsData(_vendorId);
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
          'Earnings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<EarningsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allCompletedOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Month Selector
                  _buildMonthSelector(context, provider),
                  const SizedBox(height: 16),

                  // ── Monthly Earnings Card
                  _buildMonthlyEarningsCard(provider),
                  const SizedBox(height: 16),

                  // ── Monthly Breakdown (COD vs Online)
                  _buildMonthlyBreakdown(provider),
                  const SizedBox(height: 16),

                  // ── Wallet & COD Balance Cards
                  _buildBalanceCards(provider),
                  const SizedBox(height: 16),

                  // ── Platform Fee Due Card
                  if (provider.platformFeeDue > 0) ...[
                    _buildPlatformFeeDueCard(provider),
                    const SizedBox(height: 16),
                  ],

                  // ── Action Buttons
                  _buildActionButtons(context, provider),
                  const SizedBox(height: 24),

                  // ── Recent Withdrawals
                  _buildRecentWithdrawals(context, provider),
                  const SizedBox(height: 24),

                  // ── Recent Transactions
                  _buildRecentTransactions(provider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthSelector(BuildContext context, EarningsProvider provider) {
    return GestureDetector(
      onTap: () => _showMonthYearPicker(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              provider.selectedMonthYear,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY EARNINGS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthlyEarningsCard(EarningsProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Monthly Earnings',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(provider.monthlyEarnings),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.monthlyCompletedOrders} completed orders',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY BREAKDOWN (COD vs Online/Wallet)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthlyBreakdown(EarningsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Breakdown',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),

          // COD Row
          _buildBreakdownRow(
            icon: Icons.money,
            label: 'COD Collected',
            subtitle: 'Cash received from customers',
            amount: provider.monthlyCodCollected,
            color: Colors.green.shade700,
          ),
          const Divider(height: 20),

          // Online/Wallet Row
          _buildBreakdownRow(
            icon: Icons.account_balance,
            label: 'Online/Wallet Earnings',
            subtitle: 'Added to your wallet balance',
            amount: provider.monthlyWalletEarnings,
            color: Colors.blue.shade700,
          ),
          const Divider(height: 20),

          // Platform Fee Due (from COD)
          _buildBreakdownRow(
            icon: Icons.receipt_outlined,
            label: 'Platform Fee (COD)',
            subtitle: 'Deductible from COD cash',
            amount: provider.monthlyPlatformFeeDue,
            color: AppColors.error,
            isNegative: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required double amount,
    required Color color,
    bool isNegative = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${isNegative ? "-" : ""}${Helpers.formatCurrency(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isNegative ? AppColors.error : color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BALANCE CARDS (Wallet Balance + COD Collected)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBalanceCards(EarningsProvider provider) {
    return Row(
      children: [
        // Wallet Balance (withdrawable)
        Expanded(
          child: _buildBalanceCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet Balance',
            sublabel: 'Withdrawable',
            amount: Helpers.formatCurrency(provider.walletBalance),
            color: Colors.blue.shade700,
            amountColor: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        // COD Cash In Hand
        Expanded(
          child: _buildBalanceCard(
            icon: Icons.money,
            label: 'COD Cash',
            sublabel: 'In your hand',
            amount: Helpers.formatCurrency(provider.codCollected),
            color: Colors.green.shade700,
            amountColor: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required String amount,
    required Color color,
    required Color amountColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        amount,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PLATFORM FEE DUE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPlatformFeeDueCard(EarningsProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Fee Due',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From COD orders — deductible from your cash',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Helpers.formatCurrency(provider.platformFeeDue),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButtons(BuildContext context, EarningsProvider provider) {
    return Row(
      children: [
        // Withdraw Money (only wallet balance)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: provider.availableToWithdraw > 0
                ? () {
                    Helpers.showToast(
                      'Withdraw ₹${provider.availableToWithdraw.toStringAsFixed(2)} — Coming soon!',
                    );
                  }
                : null,
            icon: const Icon(Icons.savings_outlined, size: 18),
            label: const Text('Withdraw'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // View History
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.withdrawalHistory);
            },
            icon: const Icon(Icons.history, size: 18),
            label: const Text('View History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT WITHDRAWALS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentWithdrawals(
    BuildContext context,
    EarningsProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Withdrawals',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.withdrawalHistory),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: provider.recentWithdrawals.isEmpty
              ? Center(
                  child: Text(
                    'No withdrawal history',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: provider.recentWithdrawals
                      .map((w) => _buildWithdrawalItem(w))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalItem(Map<String, dynamic> withdrawal) {
    final amount = (withdrawal['amount'] ?? 0.0).toDouble();
    final status = withdrawal['status'] ?? 'pending';
    final createdAt = withdrawal['createdAt'];
    final date = createdAt != null
        ? _formatDate((createdAt as dynamic).toDate())
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_upward,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatCurrency(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              Text(
                status.toString().toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: status == 'completed'
                      ? AppColors.success
                      : AppColors.warning,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentTransactions(EarningsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.recentTransactions.isEmpty)
          _buildEmptyTransactions()
        else
          ...provider.recentTransactions.map(
            (order) => _buildTransactionItem(order),
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(OrderModel order) {
    final displayDate = order.completedAt ?? order.createdAt;
    final date = _formatDate(displayDate);
    final itemNames = order.items
        .map((i) => '${i.name} x${i.quantity}')
        .join(', ');

    // Payment method info
    final isCod = order.paymentMethod == PaymentMethod.cod;
    final paymentLabel = isCod ? 'COD' : 'Online';
    final paymentColor = isCod ? Colors.green.shade700 : Colors.blue.shade700;
    final paymentIcon = isCod ? Icons.money : Icons.account_balance;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Payment Type Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: paymentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(paymentIcon, color: paymentColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  itemNames,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment method badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: paymentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: paymentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${Helpers.formatCurrency(order.subtotal)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              if (isCod)
                Text(
                  'Total: ${Helpers.formatCurrency(order.total)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH-YEAR PICKER
  // ═══════════════════════════════════════════════════════════════

  void _showMonthYearPicker(BuildContext context, EarningsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(
        initialMonth: provider.selectedMonth,
        initialYear: provider.selectedYear,
        onApply: (month, year) {
          provider.changeMonth(month, year);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
// MONTH-YEAR PICKER DIALOG
// ═══════════════════════════════════════════════════════════════

class _MonthYearPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  final void Function(int month, int year) onApply;

  const _MonthYearPickerDialog({
    required this.initialMonth,
    required this.initialYear,
    required this.onApply,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _month;
  late int _year;

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Month & Year',
              style: AppTextStyles.heading6.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Year
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$_year',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Month Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isSelected = monthNum == _month;

                return GestureDetector(
                  onTap: () => setState(() => _month = monthNum),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _monthLabels[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_month, _year);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
