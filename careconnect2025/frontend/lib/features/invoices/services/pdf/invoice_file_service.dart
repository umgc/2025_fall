// services/invoice_file_service.dart
import 'package:care_connect_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
 

class InvoiceFileService {
  static Future<void> openInvoicePdf(String documentLink) async {
    final url = '${ApiConstants.baseUrl}invoices/exportPDF?documentLink=$documentLink';
 
    if (await canLaunchUrlString(documentLink)) {
      await launchUrlString(documentLink, mode: LaunchMode.externalApplication);
    }
  }
}
