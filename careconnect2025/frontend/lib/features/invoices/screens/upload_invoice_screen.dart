import 'package:care_connect_app/features/invoices/widgets/ocr_review_screen.dart';
import 'package:care_connect_app/features/invoices/widgets/review_photos_screen.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:care_connect_app/features/invoices/services/invoice_service.dart';
import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/screens/invoice_detail_page.dart';
import 'package:care_connect_app/features/invoices/ai//ai_bootstrap.dart';
import 'package:care_connect_app/features/invoices/ai/ai_extractor_llm.dart';

class UploadInvoiceScreen extends StatefulWidget {
  const UploadInvoiceScreen({super.key});

  @override
  State<UploadInvoiceScreen> createState() => _UploadInvoiceScreenState();
}

class _UploadInvoiceScreenState extends State<UploadInvoiceScreen> {
  int unreadAlerts = 3;
  bool offline = false;

  @override
  void initState() {
    super.initState();
    _watchConnectivity();
  }
Future<void> _ensureAiReady() async {
  try {
   // await AIBootstrap.ensureReady();
   //check if model is available
  } catch (e) {
    _snack('AI not ready: $e');
    rethrow;
  }
}

  Future<void> _watchConnectivity() async {
    final status = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => offline = status.contains(ConnectivityResult.none));
    }
    Connectivity().onConnectivityChanged.listen((result) {
      final isOffline = result.contains(ConnectivityResult.none);
      if (mounted) setState(() => offline = isOffline);
    });
  }

  Future<void> _onUploadFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      type: FileType.custom,
      withReadStream: false,
    );
    if (res == null) return;

    String? ext(String? p) => p?.split('.').last.toLowerCase();

    final imagePaths = <String>[];
    final pdfPaths = <String>[];

    for (final f in res.files) {
      final path = f.path;
      if (path == null) continue;
      final e = ext(path);
      if (e == 'png' || e == 'jpg' || e == 'jpeg') {
        imagePaths.add(path);
      } else if (e == 'pdf') {
        pdfPaths.add(path);
      }
    }

    if (imagePaths.isEmpty && pdfPaths.isEmpty) {
      _snack('No supported files selected');
      return;
    }

    if (imagePaths.isNotEmpty) {
      final imagesAsX = imagePaths.map((p) => XFile(p)).toList();

      if (!mounted) return;
      final reviewed = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewPhotosScreen(initialPhotos: imagesAsX),
          fullscreenDialog: true,
        ),
      );
      if (!mounted) return;

      if (reviewed != null && reviewed.isNotEmpty) {
        final ocrPayload = await Navigator.push<List<Map<String, String>>>(
          context,
          MaterialPageRoute(
            builder: (_) => OcrReviewScreen(images: reviewed),
            fullscreenDialog: true,
          ),
        );
        if (!mounted) return;

     if (ocrPayload != null && ocrPayload.isNotEmpty) {
  await _ensureAiReady();

  var saved = 0;
  for (final item in ocrPayload) {
    final text = item['text'] ?? '';
    if (text.trim().isEmpty) continue;
    final inv = await AiExtractorLLM.extract(text);
    if (inv != null) {
      await InvoiceService.instance.upsert(inv);
      saved++;
    }
  }
  _snack('Saved $saved invoice(s)');
} else {
  _snack('No OCR results');
}

      } else {
        _snack('No photos selected');
      }
    }

    if (pdfPaths.isNotEmpty) {
      _snack('Selected ${pdfPaths.length} PDF(s)');
      // TODO: route PDFs to your PDF flow.
    }
  }

  Future<void> _onTakePhoto() async {
    final picker = ImagePicker();

    final first = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (first == null) return;

    if (!mounted) return;
    final reviewed = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPhotosScreen(initialPhotos: [first]),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;

    if (reviewed == null || reviewed.isEmpty) {
      _snack('No photos selected');
      return;
    }

    final ocrPayload = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => OcrReviewScreen(images: reviewed),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;

    if (ocrPayload == null || ocrPayload.isEmpty) {
      _snack('No OCR results');
      return;
    }

 
    await _ensureAiReady();

    var saved = 0;
    for (final item in ocrPayload) {
      final text = item['text'] ?? '';
      if (text.trim().isEmpty) continue;
      final inv = await AiExtractorLLM.extract(text);
      if (inv != null) {
        await InvoiceService.instance.upsert(inv);
        saved++;
      }
    }
_snack('Saved $saved invoice(s)');

  }

  Future<void> _onManualEntry() async {
    // Open the detail screen in create mode
    if (!mounted) return;
    final created = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: InvoiceFactories.empty(),
          isNew: true,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (created == null) {
      _snack('Manual entry cancelled');
      return;
    }

    await InvoiceService.instance.upsert(created);
    _snack('Invoice saved');
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Invoice'),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (unreadAlerts > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: Text(
                      unreadAlerts.toString(),
                      style: TextStyle(
                        color: cs.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const CommonDrawer(currentRoute: '/invoice-assistant/upload'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (offline) _OfflineBanner(),
            const SizedBox(height: 8),
            Text(
              'Capture or upload medical invoices and bills for automated processing',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ActionTile(
              icon: Icons.upload_file_outlined,
              label: 'Upload File',
              onTap: _onUploadFile,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take Photo',
              onTap: _onTakePhoto,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.edit_note_outlined,
              label: 'Manual Entry',
              onTap: _onManualEntry,
              // isPrimary: true, // REMOVED: This makes it an outlined button now
            ),
            const SizedBox(height: 24),
            const _SupportedFormats(),
            const SizedBox(height: 16),
            _SecureStorageCard(),
          ],
        ),
      ),
    );
  }
}

class _SecureStorageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Secure Storage',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    'All original files are securely stored and encrypted. OCR processing will extract key information while preserving your original files.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Define styles based on whether the tile is primary or outlined
    final Color backgroundColor = isPrimary ? cs.primary : cs.surface;
    final Color foregroundColor = isPrimary ? cs.onPrimary : cs.primary;
    final BorderSide borderSide = isPrimary
        ? BorderSide.none
        : BorderSide(color: cs.outline);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80), // Increased height
            child: Center( // Center the content
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row takes minimum space
                children: [
                  Icon(icon, color: foregroundColor),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Updated Widget
class _SupportedFormats extends StatelessWidget {
  const _SupportedFormats();

  @override
  Widget build(BuildContext context) {
    final formats = ['PNG', 'JPG', 'JPEG','TIFF',  'PDF'];
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported file formats',
          style: textTheme.bodySmall, // Use a smaller caption style
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: formats
              .map(
                (f) => Chip(
                  label: Text(f),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Offline mode. You can still capture invoices. They will sync when you are back online.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}