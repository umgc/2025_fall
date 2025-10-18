import '../../domain/models/...';

class GmailRaw { final String html; final Map<String,List<int>> cidMap; final DateTime date; GmailRaw(this.html,this.cidMap,this.date); }

class GmailParser {
  USPSDigest toDomain(GmailRaw r) {
    // 1) inline CIDs → data: URLs
    // 2) extract tracking links → PackageItem
    // 3) extract mailpiece images + alt/sender → MailPiece
    return USPSDigest(
      digestDateIso: r.date.toIso8601String(),
      mailpieces: /* ... */,
      packages: /* ... */,
    );
  }
}