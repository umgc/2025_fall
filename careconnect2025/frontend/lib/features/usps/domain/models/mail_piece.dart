import 'package:care_connect_app/features/usps/domain/models/action_links.dart';

class MailPiece {
  final String id;
  final String? sender, summary, imageDataUrl, dateIso;
  final ActionLinks actions;
  const MailPiece({required this.id, this.sender, this.summary, this.imageDataUrl, this.dateIso, required this.actions});
}