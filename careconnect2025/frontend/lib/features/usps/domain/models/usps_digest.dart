class USPSDigest {
  final String? digestDateIso;
  final List<MailPiece> mailpieces;
  final List<PackageItem> packages;
  const USPSDigest({this.digestDateIso, required this.mailpieces, required this.packages});
}
