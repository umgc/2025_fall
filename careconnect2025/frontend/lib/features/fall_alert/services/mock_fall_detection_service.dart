import 'dart:async';
import 'dart:math';
import '../models/fall_alert.dart';
import 'notification_service.dart';

class MockFallDetectionService {
  MockFallDetectionService._();
  static final MockFallDetectionService _i = MockFallDetectionService._();
  factory MockFallDetectionService() => _i;

  final _rng = Random();
  Timer? _timer;
  final _alerts = StreamController<FallAlert>.broadcast();
  Stream<FallAlert> get alerts$ => _alerts.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _emitRandom());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> emitNow() => _emitRandom();

  Future<void> _emitRandom() async {
    // Example directory of patients with emergency contacts
    final patients = [
      {
        'id': 'p1',
        'name': 'John Carter',
        'phone': '18002428447',
        'ecName': 'Sarah Carter',
        'ecPhone': '18002428447',
      },
      {
        'id': 'p2',
        'name': 'Amelia Lopez',
        'phone': '18002428447',
        'ecName': 'Luis Lopez',
        'ecPhone': '18002428447',
      },
      {
        'id': 'p3',
        'name': 'Michael Chen',
        'phone': '18002428447',
        'ecName': 'Grace Chen',
        'ecPhone': '18002428447',
      },
    ];

    final picked = patients[_rng.nextInt(patients.length)];
    final isCamera = _rng.nextBool();
    final hasVideo = isCamera && _rng.nextBool();

    final alert = FallAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: picked['id']!,
      patientName: picked['name']!,
      detectedAtUtc: DateTime.now().toUtc(),
      source: isCamera ? 'camera' : 'watch',
      hasLiveVideo: hasVideo,
      liveVideoUrl: hasVideo ? Uri.parse('https://example.com/live/${picked['id']}') : null,
      patientPhone: picked['phone'],
      emergencyContactName: picked['ecName'],
      emergencyContactPhone: picked['ecPhone'],
    );

    _alerts.add(alert);
    await NotificationService().showFallAlert(alert);
  }
}
