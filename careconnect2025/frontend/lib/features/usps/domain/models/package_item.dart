class PackageItem {
  final String trackingNumber;
  final String? sender;
  final String? expectedDateIso;
  final ActionLinks actions;

  const PackageItem({
    required this.trackingNumber,
    this.sender,
    this.expectedDateIso,
    required this.actions,
  });
}
