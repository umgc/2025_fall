import 'package:care_connect_app/features/invoices/services/invoice_ocr_llm_api.dart';
import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/screens/invoice_detail_page.dart';
import 'package:care_connect_app/features/invoices/widgets/review_photos_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadInvoicePage extends StatefulWidget {
  const UploadInvoicePage({super.key});

  @override
  State<UploadInvoicePage> createState() => _UploadInvoicePageState();
}

class _UploadInvoicePageState extends State<UploadInvoicePage> {
  bool offline = false;

  @override
  void initState() {
    super.initState();
    _watchConnectivity();
  }

  Future<void> _watchConnectivity() async {
    final status = await Connectivity().checkConnectivity();
    if (mounted)
      setState(() => offline = status.contains(ConnectivityResult.none));
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted)
        setState(() => offline = result.contains(ConnectivityResult.none));
    });
  }

  Future<void> _onUploadFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      type: FileType.custom,
      withReadStream: false,
    );
    if (picked == null) return;

    String? ext(String? p) => p?.split('.').last.toLowerCase();
    final imageFiles = <XFile>[];
    final pdfPaths = <String>[];

    for (final f in picked.files) {
      final path = f.path;
      if (path == null) continue;
      final e = ext(f.name);
      if (e == 'png' || e == 'jpg' || e == 'jpeg') {
        // For images, create XFile properly for both web and mobile
        if (kIsWeb) {
          // On web, create XFile from bytes
          if (f.bytes != null) {
            imageFiles.add(XFile.fromData(f.bytes!, name: f.name));
          }
        } else {
          // On mobile, use path if available
          if (f.path != null) {
            imageFiles.add(XFile(f.path!));
          }
        }
      } else if (e == 'pdf') {
        // For PDFs, we still need paths for now
        // TODO: Update PDF handling for web compatibility
        if (f.path != null) {
          pdfPaths.add(f.path!);
        } else if (kIsWeb) {
          _snack('PDF upload on web is not currently supported. Please use mobile device or upload images instead.');
          return;
        }
      }
    }

    if (imageFiles.isEmpty && pdfPaths.isEmpty) {
      _snack('No supported files selected');
      return;
    }

    // Images flow
    if (imageFiles.isNotEmpty) {
      final reviewed = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewPhotosScreen(
            initialPhotos: imageFiles,
          ),
          fullscreenDialog: true,
        ),
      );
      if (!mounted) return;

      if (reviewed == null || reviewed.isEmpty) {
        _snack('No photos selected');
        return;
      }

      final res = await runWithBlockingDialog<InvoiceResponseDto?>(
        context: context,
        message: 'Extracting invoice data from images. This may take a minute.',
        future: InvoiceOcrLlmApi.extractWithLlm(images: reviewed),
      );

      await _handleExtractResult(
        res,
        failMessage: 'Could not extract invoice from images',
      );
      if (!mounted) return;
    }

    // PDFs flow
    if (pdfPaths.isNotEmpty) {
      final res = await runWithBlockingDialog<InvoiceResponseDto?>(
        context: context,
        message:
            'Extracting invoice data from PDF files. This may take a minute.',
        future: InvoiceOcrLlmApi.extractWithLlm(pdfPaths: pdfPaths),
      );

      await _handleExtractResult(
        res,
        failMessage: 'Could not extract invoice from PDF files',
      );
      if (!mounted) return;
    }
  }

  Future<void> _onTakePhoto() async {
    final first = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (first == null) return;

    if (!mounted) return;    
    
    final reviewed = await Navigator.of(context, rootNavigator: true).push<List<XFile>>(
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

    final res = await runWithBlockingDialog<InvoiceResponseDto?>(
      context: context,
      message: 'Extracting invoice data from images. This may take a minute.',
      future: InvoiceOcrLlmApi.extractWithLlm(images: reviewed),
    );

    await _handleExtractResult(
      res,
      failMessage: 'Could not extract invoice from images',
    );
  }

  Future<void> _handleExtractResult(
    InvoiceResponseDto? res, {
    required String failMessage,
  }) async {
    if (res == null) {
      _snack(failMessage);
      return;
    }

    // Duplicate check: ask proceed or cancel
    if (res.duplicate) {
      final proceed = await _confirmDuplicateProceed(
        context: context,
        message: res.message,
        duplicateInvoiceNumber: res.duplicateInvoiceNumber,
      );
      if (!proceed) {
        // user canceled, do nothing
        return;
      }
    }

    // Do not save here. Go to detail so user can review and save there.
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: res.invoice,
          isNew: res.invoice.id.isEmpty,
        ),
      ),
    );
  }

  Future<void> _onManualEntry() async {
    if (!mounted) return;
    // No saving here. Just open detail in create mode.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: InvoiceFactories.empty(),
          isNew: true,
        ),
      ),
    );
   
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (offline) const _OfflineBanner(),
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
            ),
            const SizedBox(height: 24),
            const _SupportedFormats(),
            const SizedBox(height: 16),
            Card.outlined(
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
                          Text(
                            'Secure Storage',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDuplicateProceed({
    required BuildContext context,
    String? message,
    String? duplicateInvoiceNumber,
  }) async {
    final text = StringBuffer();
    text.writeln(
      message ??
          'This invoice appears to be a duplicate of one already in the system.',
    );
    if (duplicateInvoiceNumber != null && duplicateInvoiceNumber.isNotEmpty) {
      text.writeln('Existing invoice number: $duplicateInvoiceNumber');
    }
    text.write('Do you want to proceed anyway?');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Possible duplicate'),
        content: Text(text.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

/// Non-dismissible progress dialog wrapper
Future<T?> runWithBlockingDialog<T>({
  required BuildContext context,
  required String message,
  required Future<T> future,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Please wait',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final result = await future;
    return result;
  } finally {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
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

class _SupportedFormats extends StatelessWidget {
  const _SupportedFormats();

  @override
  Widget build(BuildContext context) {
    final formats = ['PNG', 'JPG', 'JPEG', 'TIFF', 'PDF'];
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supported file formats', style: textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: formats.map((f) => Chip(label: Text(f))).toList(),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: cs.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Offline mode. You can still capture invoices. They will sync when you are back online.',
            ),
          ),
        ],
      ),
    );
  }
}
