import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msa_hackathon/main.dart';

class TestAttendeeRepository extends AttendeeRepository {
  static const _unknown = AttendeeDetail(
    id: 'unknown-template',
    name: 'Unknown Guest',
    role: 'Identity not recognized',
    location: 'Manual Review Required',
    status: AttendeeStatus.unknown,
    imageUrl: null,
    email: 'Unavailable',
    organization: 'Unknown',
    note: 'No verified attendee match was found. Manual review is required.',
  );

  final Map<String, AttendeeDetail> _details = {
    'elias-vance': const AttendeeDetail(
      id: 'elias-vance',
      name: 'Elias Vance',
      role: 'VIP Security Guest',
      location: 'Main Entry Checkpoint',
      status: AttendeeStatus.accepted,
      imageUrl: null,
      email: 'elias.vance@syntheticeye.local',
      organization: 'Synthetic Eye Labs',
      note: 'On the accepted attendee list. Access approved for event entry.',
    ),
    'marcus-thorne': const AttendeeDetail(
      id: 'marcus-thorne',
      name: 'Marcus Thorne',
      role: 'Former Sponsor Contact',
      location: 'Executive Suite Lounge',
      status: AttendeeStatus.rejected,
      imageUrl: null,
      email: 'marcus.thorne@syntheticeye.local',
      organization: 'Archon Partners',
      note:
          'A record exists, but this person is not on the accepted attendee list.',
    ),
  };

  late final List<AttendeeSummary> _history = [
    _details['elias-vance']!.toSummary(
      scannedAt: DateTime.now().subtract(const Duration(minutes: 18)),
      confidence: 0.9982,
      source: ScanSource.camera,
    ),
    _details['marcus-thorne']!.toSummary(
      scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
      confidence: 0.7641,
      source: ScanSource.gallery,
    ),
  ];

  @override
  Future<AttendeeDetail> getAttendeeDetail(String id) async {
    return _details[id] ?? _unknown;
  }

  @override
  Future<List<AttendeeDetail>> listMemberProfiles() async {
    return _details.values.toList();
  }

  @override
  Future<List<AttendeeSummary>> listAttendees({
    HistoryFilter filter = HistoryFilter.all,
  }) async {
    final status = filter.statusOrNull;
    final filtered = status == null
        ? _history
        : _history.where((entry) => entry.status == status).toList();
    filtered.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return filtered;
  }

  @override
  Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required ScanSource source,
    bool preview = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EnrollmentBatchResult> enrollMembers({
    required List<EnrollmentMemberDraft> members,
  }) async {
    return const EnrollmentBatchResult(
      enrolledCount: 0,
      totalSavedImages: 0,
      members: [],
    );
  }

  @override
  Future<ApprovedGuestsConfig> getApprovedGuests() async {
    return const ApprovedGuestsConfig(names: ['Elias Vance']);
  }

  @override
  Future<ApprovedGuestsConfig> saveApprovedGuests(List<String> names) async {
    return ApprovedGuestsConfig(names: names);
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  testWidgets('app opens on splash then advances to onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SyntheticEyeApp());

    expect(find.text('ENTRY CONTROL IN MOTION'), findsOneWidget);
    expect(find.text('GET STARTED'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('Precision Identity Redefined'), findsOneWidget);
  });

  testWidgets('onboarding supports swipe and auth navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SyntheticEyeApp());
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('Precision Identity Redefined'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-390, 0));
    await tester.pumpAndSettle();
    expect(find.text('Capture Every Guest In Seconds'), findsOneWidget);

    await tester.tap(find.text('EXISTING ACCOUNT LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('history filter chips and attendee sheet work', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(repository: TestAttendeeRepository()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Scan History'), findsOneWidget);
    expect(find.text('Elias Vance'), findsOneWidget);

    await tester.tap(find.text('Rejected'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Marcus Thorne'), findsOneWidget);
    expect(find.text('Elias Vance'), findsNothing);

    await tester.tap(find.text('Marcus Thorne'));
    await tester.pumpAndSettle();

    expect(find.text('Former Sponsor Contact'), findsOneWidget);
    expect(find.text('ORGANIZATION'), findsOneWidget);
  });
}
