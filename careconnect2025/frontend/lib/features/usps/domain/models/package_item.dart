class PackageItem {
  final String trackingNumber;
  final String? expectedDateIso;
  final ActionLinks actions;
  const PackageItem({required this.trackingNumber, this.expectedDateIso, required this.actions});
}