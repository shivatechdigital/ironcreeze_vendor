enum VendorStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  suspended('suspended', 'Suspended');

  final String value;
  final String displayName;

  const VendorStatus(this.value, this.displayName);

  static VendorStatus fromString(String status) {
    return VendorStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => VendorStatus.pending,
    );
  }
}
