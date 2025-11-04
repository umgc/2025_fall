import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:care_connect_app/features/usps/data/parsers/gmail_parser.dart';

void main() {
  final sampleHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>USPS Informed Delivery Daily Digest</title>
  <meta name="date" content="Fri, 14 Feb 2025 08:30:00 -0500">
</head>
<body>
  <div class="hero">
    <h1>Informed Delivery® Daily Digest for Friday, February 14, 2025</h1>
    <time class="digest-date" datetime="2025-02-14T13:30:00Z">Friday, February 14, 2025</time>
  </div>

  <section id="packages">
    <h2>Packages</h2>
    <article class="package">
      <p><strong>Tracking Number:</strong> <span class="tracking-number">9400100252801234567890</span></p>
      <p><strong>Expected Delivery Day:</strong> Tuesday, February 18, 2025</p>
      <p><a class="track-link" href="https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=9400100252801234567890">Track Package</a></p>
      <p><a class="dashboard-link" href="https://informeddelivery.usps.com/dashboard">View Dashboard</a></p>
    </article>
  </section>

  <section id="mailpieces">
    <h2>Mailpieces</h2>
    <div class="mailpiece" data-mailpiece-id="mp-2025-02-14-1">
      <img src="cid:mailpiece_1" alt="Image of letter from ACME Bank">
      <p class="sender">ACME Bank</p>
      <p class="summary">Your monthly statement is ready.</p>
    </div>
    <div class="mailpiece" data-mailpiece-id="mp-2025-02-14-2">
      <img src="cid:mailpiece_2" alt="Image of postcard from City Water">
      <p class="sender">City Water</p>
      <p class="summary">Billing reminder.</p>
    </div>
  </section>
</body>
</html>
''';

  test('GmailParser parses sample digest HTML', () {
    final parser = GmailParser();
    final raw = GmailRaw(
      sampleHtml,
      {
        'mailpiece_1': 'data:image/png;base64,${base64Encode('piece1'.codeUnits)}',
        'mailpiece_2': 'data:image/png;base64,${base64Encode('piece2'.codeUnits)}',
      },
      DateTime.utc(2025, 2, 14, 13, 30),
    );

    final digest = parser.toDomain(raw);

    expect(digest.digestDateIso, '2025-02-14T13:30:00.000Z');
    expect(digest.packages.length, 1);
    expect(digest.packages.first.trackingNumber, '9400100252801234567890');
    expect(digest.packages.first.actions.track,
        contains('9400100252801234567890'));

    expect(digest.mailpieces.length, 2);
    expect(digest.mailpieces.first.sender, 'ACME Bank');
    expect(digest.mailpieces.first.summary, 'Your monthly statement is ready.');
    expect(digest.mailpieces.first.imageDataUrl,
        startsWith('data:image/png;base64,'));
  });
}
