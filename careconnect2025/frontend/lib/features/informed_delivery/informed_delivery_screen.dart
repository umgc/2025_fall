import 'package:flutter/material.dart';
import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:care_connect_app/services/informed_delivery_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:care_connect_app/config/env_constant.dart';
import 'package:care_connect_app/assets/usps_digest_mock.dart';

/// ---- Domain models ----
class EmailMessage {
  final String id;
  final DateTime expectedAt;
  final List<String>
  imageUrls; // Inline/attachment image URLs or local file URIs

  EmailMessage({
    required this.id,
    required this.expectedAt,
    required this.imageUrls,
  });
}

class UspsDigest {
  final DateTime digestDate;
  final List<UspsMailpiece> mailpieces;
  final List<UspsPackage> packages;

  UspsDigest({
    required this.digestDate,
    required this.mailpieces,
    required this.packages,
  });
}

class UspsMailpiece {
  final String id;
  final String sender;
  final String summary;
  final DateTime dateIso;
  final String imageDataUrl; // models:*;base64,XXXX
  final UspsActions actions;
  Uint8List? _decoded; // lazy cache

  UspsMailpiece({
    required this.id,
    required this.sender,
    required this.summary,
    required this.dateIso,
    required this.imageDataUrl,
    required this.actions,
  });

  /// Decode the models URL to bytes (memoized).
  Uint8List? get bytes {
    _decoded ??= _decodeDataUrl(imageDataUrl);
    return _decoded;
  }
}

class UspsPackage {
  final String trackingNumber;
  final DateTime expectedDateIso;
  final UspsActions actions;

  UspsPackage({
    required this.trackingNumber,
    required this.expectedDateIso,
    required this.actions,
  });
}

class UspsActions {
  final String? track;
  final String? redelivery;
  final String? dashboard;

  UspsActions({this.track, this.redelivery, this.dashboard});
}

/// Groups emails by the calendar day (yyyy-mm-dd) and flattens to image lists.
Map<DateTime, List<String>> groupImagesByDate(List<EmailMessage> emails) {
  final Map<String, List<String>> temp = {};
  for (final m in emails) {
    final dayKey = _dayKey(m.expectedAt);
    temp.putIfAbsent(dayKey, () => []);
    temp[dayKey]!.addAll(m.imageUrls);
  }

  // Convert back to DateTime keys at midnight for sorting & display
  final Map<DateTime, List<String>> result = {};
  temp.forEach((k, v) {
    final parts = k.split('-').map(int.parse).toList();
    result[DateTime(parts[0], parts[1], parts[2])] = v;
  });
  return result;
}

String _dayKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

String formatDay(DateTime dt) {
  // e.g., Mon, Oct 13, 2025
  const weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const month = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final wd = weekday[(dt.weekday + 6) % 7]; // make Monday index 0
  final mo = month[dt.month - 1];
  return '$wd, $mo ${dt.day}, ${dt.year}';
}

/// ---- App ----
class InformedDeliveryScreen extends StatefulWidget {
  const InformedDeliveryScreen({super.key});

  @override
  State<InformedDeliveryScreen> createState() => _InformedDeliveryScreenState();
}

class _InformedDeliveryScreenState extends State<InformedDeliveryScreen> {
  // final enableUSPSDigest = getEnableUSPSDigest().toLowerCase() == 'true';
  // final enableMockUSPSDigest =
  //     getEnableMockUSPSDigest().toLowerCase() == 'true';

  final enableUSPSDigest = true;
  final enableMockUSPSDigest = true;

  Map<DateTime, List<String>> _imagesByDate = const {};
  List<DateTime> _sortedDays = const [];
  DateTime? _selectedDay;
  bool isLoadingData = false;
  int _totalMailpieces = 0;

  @override
  void initState() {
    super.initState();
    _loadDigestData();

  }

  Future<UspsDigest> _fetchRealDigest() async {
    try {
      // Example: Call your real API
      final response = await InformedDeliveryService.fetchInformedDelivery();
      final digest = parseUspsDigestResponse(response);
      return digest;
    } catch (e, st) {
      // Log or show a message
      debugPrint('❌ Error fetching USPS digest: $e');
      debugPrintStack(stackTrace: st);

      // Return a fallback empty digest so the UI still works
      return UspsDigest(
        digestDate: DateTime.now(),
        mailpieces: const [],
        packages: const [],
      );
    }
  }

  Future<void> _loadDigestData() async {
    setState(() => isLoadingData = true);
    try {
      // Base digest: real if enabled, otherwise empty
      final UspsDigest base = enableUSPSDigest
          ? await _fetchRealDigest()
          : UspsDigest(
              digestDate: DateTime.now(),
              mailpieces: const [],
              packages: const [],
            );

      // Optionally apply mock models
      UspsDigest combined = base;
      if (enableMockUSPSDigest) {
        debugPrint('⚠️ Using mock mailpieces for demo purposes.');
        final mockMap = buildMockUspsDigestMap();
        final mock = parseUspsDigestResponse(mockMap);
        combined = mergeDigests(base, mock);
      }

      _hydrateDigestData(combined);
    } finally {
      if (mounted) setState(() => isLoadingData = false);
    }
  }

  void _hydrateDigestData(UspsDigest digest) {
    // Map each mailpiece into your existing EmailMessage shape
    final List<EmailMessage> inboxLike = digest.mailpieces.map((m) {
      return EmailMessage(
        id: m.id,
        expectedAt: m.dateIso, // bucket by calendar day using dateIso
        imageUrls: [if (m.imageDataUrl.isNotEmpty) m.imageDataUrl],
      );
    }).toList();

    // Reuse your existing grouping/sorting logic
    _hydrateData(inboxLike);
  }

  void _hydrateData(List<EmailMessage> inbox) {
    final grouped = groupImagesByDate(inbox);
    final days = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first
    setState(() {
      _imagesByDate = grouped;
      _sortedDays = days;
      _selectedDay = days.isNotEmpty ? days.first : null;
      _totalMailpieces = inbox.length;
    });
  }

  /// Accepts either:
  /// - Map<String, dynamic> (already decoded), or
  /// - String (JSON text)
  UspsDigest parseUspsDigestResponse(Object response) {
    final Map<String, dynamic> map = switch (response) {
      final String s => _looseJsonDecode(s),
      final Map m => m.map((k, v) => MapEntry(k.toString(), v)),
      _ => throw ArgumentError(
        'Unsupported response type: ${response.runtimeType}',
      ),
    };

    DateTime _parseDate(Object? v) {
      if (v is String) return DateTime.parse(v);
      throw FormatException('Invalid date value: $v');
    }

    UspsActions _parseActions(Object? v) {
      final m = (v is Map)
          ? v.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      return UspsActions(
        track: m['track']?.toString(),
        redelivery: m['redelivery']?.toString(),
        dashboard: m['dashboard']?.toString(),
      );
    }

    List<UspsMailpiece> _parseMailpieces(Object? v) {
      if (v is List) {
        return v.map((e) {
          final m = (e as Map).map((k, v) => MapEntry(k.toString(), v));
          return UspsMailpiece(
            id: m['id']?.toString() ?? '',
            sender: m['sender']?.toString() ?? '',
            summary: m['summary']?.toString() ?? '',
            imageDataUrl: m['imageDataUrl']?.toString() ?? '',
            dateIso: _parseDate(m['dateIso']),
            actions: _parseActions(m['actions']),
          );
        }).toList();
      }
      return const [];
    }

    List<UspsPackage> _parsePackages(Object? v) {
      if (v is List) {
        return v.map((e) {
          final m = (e as Map).map((k, v) => MapEntry(k.toString(), v));
          return UspsPackage(
            trackingNumber: m['trackingNumber']?.toString() ?? '',
            expectedDateIso: _parseDate(m['expectedDateIso']),
            actions: _parseActions(m['actions']),
          );
        }).toList();
      }
      return const [];
    }

    return UspsDigest(
      digestDate: _parseDate(map['digestDate']),
      mailpieces: _parseMailpieces(map['mailpieces']),
      packages: _parsePackages(map['packages']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedImages = _selectedDay == null
        ? <String>[]
        : _imagesByDate[_selectedDay] ?? <String>[];

    return Scaffold(
      drawer: const CommonDrawer(currentRoute: '/informed-delivery'),
      appBar: AppBarHelper.createAppBar(
        context,
        title: 'Informed Delivery (${_totalMailpieces})',
        centerTitle: true,
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: null, // Implement refresh logic
          ),
        ],
      ),
      body: _buildInformedDeliveryView(),
    );
  }

  Widget _buildInformedDeliveryView() {
    final selectedImages = _selectedDay == null
        ? <String>[]
        : _imagesByDate[_selectedDay] ?? <String>[];
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime>(
                  initialValue: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Select expected date',
                    border: OutlineInputBorder(),
                  ),
                  items: _sortedDays.map((day) {
                    final count = _imagesByDate[day]?.length ?? 0;
                    return DropdownMenuItem<DateTime>(
                      value: day,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(formatDay(day))],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDay = val),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: isLoadingData ? null : _onRefresh,
                icon: isLoadingData
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isLoadingData ? 'Refreshing...' : 'Refresh'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: selectedImages.isEmpty
              ? const _EmptyState()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.4,
                        ),
                    padding: const EdgeInsets.all(8),
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      final url = selectedImages[index];
                      return _ImageTile(
                        url: url,
                        onTap: () => _openImageViewer(url),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    setState(() => isLoadingData = true);
    try {
      final UspsDigest base = enableUSPSDigest
          ? await _fetchRealDigest()
          : UspsDigest(
              digestDate: DateTime.now(),
              mailpieces: const [],
              packages: const [],
            );

      UspsDigest combined = base;
      if (enableMockUSPSDigest) {
        debugPrint('⚠️ Using mock mailpieces during refresh.');
        final mockMap = buildMockUspsDigestMap();
        final mock = parseUspsDigestResponse(mockMap);
        combined = mergeDigests(base, mock);
      }

      _hydrateDigestData(combined);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enableUSPSDigest
                  ? 'Mail models refreshed (API ${enableMockUSPSDigest ? "+ mock" : ""}).'
                  : 'Mail models refreshed (mock only).',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Error refreshing mail models: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoadingData = false);
    }
  }

  void _openImageViewer(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 5,
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Uint8List? _decodeDataUrl(String? dataUrl) {
  if (dataUrl == null) return null;
  final i = dataUrl.indexOf(';base64,');
  if (!dataUrl.startsWith('models:') || i == -1) return null;
  final comma = dataUrl.indexOf(',', i);
  if (comma == -1) return null;
  final base64Part = dataUrl.substring(comma + 1);
  try {
    return base64Decode(base64Part);
  } catch (_) {
    return null;
  }
}

/// Some APIs (or logs) hand us "relaxed" JSON-like text (unquoted keys, single quotes).
/// This normalizer tries to coerce it to valid JSON before jsonDecode().
Map<String, dynamic> _looseJsonDecode(String s) {
  // 1) Replace single quotes around strings to double quotes (safe heuristic)
  var t = s.replaceAllMapped(
    RegExp(r"'([^']*)'"),
    (m) => '"${m.group(1)!.replaceAll(r'"', r'\"')}"',
  );

  // 2) Quote unquoted keys: {key: value} -> {"key": value}
  t = t.replaceAllMapped(
    RegExp(r'([{\s,])([A-Za-z_][A-Za-z0-9_]*)\s*:', multiLine: true),
    (m) => '${m.group(1)}"${m.group(2)}":',
  );

  // Now standard JSON
  final decoded = jsonDecode(t);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  throw const FormatException('Expected a JSON object at top level.');
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  const _ImageTile({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDataUrl = url.startsWith('models:');
    Widget imageWidget;

    if (isDataUrl) {
      final bytes = _decodeDataUrl(url);
      if (bytes == null) {
        imageWidget = const Center(
          child: Icon(Icons.broken_image_outlined, size: 48),
        );
      } else if (url.startsWith('models:image/svg+xml')) {
        // SVG handling
        imageWidget = SvgPicture.memory(bytes, fit: BoxFit.cover);
      } else {
        // PNG, JPG, etc.
        imageWidget = Image.memory(bytes, fit: BoxFit.cover);
      }
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      );
    }

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: imageWidget,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_search_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'No mail for this expected date',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Pick another expected date from the dropdown above.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

UspsDigest mergeDigests(UspsDigest a, UspsDigest b) {
  // Newest of the two digests
  final digestDate = (a.digestDate.isAfter(b.digestDate))
      ? a.digestDate
      : b.digestDate;

  // --- Mailpieces: dedupe by id, keep the "real" one if collision ---
  final Map<String, UspsMailpiece> byId = {
    for (final m in b.mailpieces) m.id: m, // start with mock
    for (final m in a.mailpieces) m.id: m, // overwrite with real
  };
  final mergedMail = byId.values.toList()
    ..sort((x, y) => y.dateIso.compareTo(x.dateIso)); // newest first

  // --- Packages: dedupe by trackingNumber ---
  final Map<String, UspsPackage> byTrack = {
    for (final p in b.packages) p.trackingNumber: p, // mock
    for (final p in a.packages) p.trackingNumber: p, // real overwrites
  };
  final mergedPkgs = byTrack.values.toList()
    ..sort((x, y) => y.expectedDateIso.compareTo(x.expectedDateIso));

  return UspsDigest(
    digestDate: digestDate,
    mailpieces: mergedMail,
    packages: mergedPkgs,
  );
}
