import '../domain/models/...';
import 'providers/gmail_service.dart';
import 'providers/outlook_service.dart';
import 'parsers/gmail_parser.dart';
import 'parsers/outlook_parser.dart';

class UspsDigestRepositoryImpl implements UspsDigestRepository {
  final GmailService gmail;
  final OutlookService outlook;
  final GmailParser gParser;
  final OutlookParser oParser;

  UspsDigestRepositoryImpl({required this.gmail, required this.outlook, required this.gParser, required this.oParser});

  @override
  Future<USPSDigest?> fromGmail() async {
    final raw = await gmail.fetchRaw();      // html + cid map + date
    return raw == null ? null : gParser.toDomain(raw);
  }

  @override
  Future<USPSDigest?> fromOutlook() async {
    final raw = await outlook.fetchRaw();
    return raw == null ? null : oParser.toDomain(raw);
  }

  @override
  Future<USPSDigest?> latestDigest() async =>
      (await fromGmail()) ?? (await fromOutlook());
}