part of '../main.dart';

enum AppPhase { splash, onboarding, login, signup, shell }

enum ProfileMenuAction { help, logout }

enum AttendeeStatus { accepted, rejected, unknown }

AttendeeStatus attendeeStatusFromJson(String value) => switch (value) {
  'accepted' => AttendeeStatus.accepted,
  'rejected' => AttendeeStatus.rejected,
  _ => AttendeeStatus.unknown,
};

extension AttendeeStatusX on AttendeeStatus {
  String get wireValue => switch (this) {
    AttendeeStatus.accepted => 'accepted',
    AttendeeStatus.rejected => 'rejected',
    AttendeeStatus.unknown => 'unknown',
  };

  String get label => switch (this) {
    AttendeeStatus.accepted => 'Accepted',
    AttendeeStatus.rejected => 'Rejected',
    AttendeeStatus.unknown => 'Unknown',
  };

  String get badgeLabel => switch (this) {
    AttendeeStatus.accepted => 'ACCEPTED',
    AttendeeStatus.rejected => 'REJECTED',
    AttendeeStatus.unknown => 'UNKNOWN',
  };

  Color get color => switch (this) {
    AttendeeStatus.accepted => AppPalette.accepted,
    AttendeeStatus.rejected => AppPalette.rejected,
    AttendeeStatus.unknown => AppPalette.unknown,
  };

  String get resultTitle => switch (this) {
    AttendeeStatus.accepted => 'Accepted Attendee',
    AttendeeStatus.rejected => 'Rejected Match',
    AttendeeStatus.unknown => 'Unknown Guest',
  };

  String get resultDescription => switch (this) {
    AttendeeStatus.accepted =>
      'This attendee is on the accepted guest list and can be cleared for entry.',
    AttendeeStatus.rejected =>
      'A record was found, but this person is not on the accepted attendee list.',
    AttendeeStatus.unknown =>
      'No verified attendee match was found. Manual review is required.',
  };

  String get membershipText => switch (this) {
    AttendeeStatus.accepted => 'On the accepted attendee list.',
    AttendeeStatus.rejected => 'Not on the accepted attendee list.',
    AttendeeStatus.unknown => 'Unknown / not on the accepted attendee list.',
  };
}

enum HistoryFilter { all, accepted, rejected, unknown }

extension HistoryFilterX on HistoryFilter {
  String get label => switch (this) {
    HistoryFilter.all => 'All',
    HistoryFilter.accepted => 'Accepted',
    HistoryFilter.rejected => 'Rejected',
    HistoryFilter.unknown => 'Unknown',
  };

  AttendeeStatus? get statusOrNull => switch (this) {
    HistoryFilter.all => null,
    HistoryFilter.accepted => AttendeeStatus.accepted,
    HistoryFilter.rejected => AttendeeStatus.rejected,
    HistoryFilter.unknown => AttendeeStatus.unknown,
  };
}

enum ScanSource { camera, gallery }

ScanSource scanSourceFromJson(String value) => switch (value) {
  'camera' => ScanSource.camera,
  _ => ScanSource.gallery,
};

extension ScanSourceX on ScanSource {
  String get wireValue => switch (this) {
    ScanSource.camera => 'camera',
    ScanSource.gallery => 'gallery',
  };

  String get label => switch (this) {
    ScanSource.camera => 'Live camera',
    ScanSource.gallery => 'Camera roll',
  };
}

class AttendeeSummary {
  const AttendeeSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.scannedAt,
    required this.status,
    required this.imageUrl,
    required this.confidence,
    required this.source,
  });

  final String id;
  final String name;
  final String role;
  final String location;
  final DateTime scannedAt;
  final AttendeeStatus status;
  final String? imageUrl;
  final double confidence;
  final ScanSource source;

  String get timeLabel => formatClock(scannedAt);

  factory AttendeeSummary.fromJson(Map<String, dynamic> json) {
    return AttendeeSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      location: json['location'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String).toLocal(),
      status: attendeeStatusFromJson(json['status'] as String),
      imageUrl: json['imageUrl'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      source: scanSourceFromJson(json['source'] as String),
    );
  }

  AttendeeSummary copyWith({
    String? id,
    String? name,
    String? role,
    String? location,
    DateTime? scannedAt,
    AttendeeStatus? status,
    String? imageUrl,
    double? confidence,
    ScanSource? source,
  }) {
    return AttendeeSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      scannedAt: scannedAt ?? this.scannedAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
    );
  }
}

class AttendeeDetail {
  const AttendeeDetail({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.status,
    required this.imageUrl,
    required this.email,
    required this.organization,
    required this.note,
  });

  final String id;
  final String name;
  final String role;
  final String location;
  final AttendeeStatus status;
  final String? imageUrl;
  final String email;
  final String organization;
  final String note;

  factory AttendeeDetail.fromJson(Map<String, dynamic> json) {
    return AttendeeDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      location: json['location'] as String,
      status: attendeeStatusFromJson(json['status'] as String),
      imageUrl: json['imageUrl'] as String?,
      email: json['email'] as String,
      organization: json['organization'] as String,
      note: json['note'] as String,
    );
  }

  AttendeeSummary toSummary({
    required DateTime scannedAt,
    required double confidence,
    required ScanSource source,
  }) {
    return AttendeeSummary(
      id: id,
      name: name,
      role: role,
      location: location,
      scannedAt: scannedAt,
      status: status,
      imageUrl: imageUrl,
      confidence: confidence,
      source: source,
    );
  }
}

class ScanResult {
  const ScanResult({
    required this.status,
    required this.detail,
    required this.confidence,
    required this.source,
    required this.scannedAt,
    this.summary,
  });

  final AttendeeStatus status;
  final AttendeeDetail detail;
  final double confidence;
  final ScanSource source;
  final DateTime scannedAt;
  final ScanSummary? summary;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      status: attendeeStatusFromJson(json['status'] as String),
      detail: AttendeeDetail.fromJson(json['detail'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      source: scanSourceFromJson(json['source'] as String),
      scannedAt: DateTime.parse(json['scannedAt'] as String).toLocal(),
      summary: json['summary'] is Map<String, dynamic>
          ? ScanSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : json['summary'] is Map
          ? ScanSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map))
          : null,
    );
  }
}

class EnrollmentMemberDraft {
  const EnrollmentMemberDraft({
    required this.label,
    required this.images,
    this.status = AttendeeStatus.accepted,
  });

  final String label;
  final List<Uint8List> images;
  final AttendeeStatus status;
}

class ScanFaceMatch {
  const ScanFaceMatch({
    required this.name,
    required this.status,
    required this.confidence,
  });

  final String name;
  final AttendeeStatus status;
  final double confidence;

  factory ScanFaceMatch.fromJson(Map<String, dynamic> json) {
    return ScanFaceMatch(
      name: json['name'] as String,
      status: attendeeStatusFromJson(json['status'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class ScanSummary {
  const ScanSummary({
    required this.faceCount,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.unknownCount,
    required this.status,
    required this.matches,
  });

  final int faceCount;
  final int acceptedCount;
  final int rejectedCount;
  final int unknownCount;
  final AttendeeStatus status;
  final List<ScanFaceMatch> matches;

  factory ScanSummary.fromJson(Map<String, dynamic> json) {
    return ScanSummary(
      faceCount: json['faceCount'] as int,
      acceptedCount: json['acceptedCount'] as int,
      rejectedCount: json['rejectedCount'] as int,
      unknownCount: json['unknownCount'] as int,
      status: attendeeStatusFromJson(json['status'] as String),
      matches: (json['matches'] as List<dynamic>)
          .map(
            (entry) =>
                ScanFaceMatch.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
    );
  }
}

class ApprovedGuestsConfig {
  const ApprovedGuestsConfig({required this.names});

  final List<String> names;

  factory ApprovedGuestsConfig.fromJson(Map<String, dynamic> json) {
    return ApprovedGuestsConfig(
      names: (json['names'] as List<dynamic>)
          .map((entry) => entry as String)
          .toList(),
    );
  }
}

class EnrollmentMemberResult {
  const EnrollmentMemberResult({
    required this.attendee,
    required this.savedImages,
  });

  final AttendeeDetail attendee;
  final int savedImages;

  factory EnrollmentMemberResult.fromJson(Map<String, dynamic> json) {
    return EnrollmentMemberResult(
      attendee: AttendeeDetail.fromJson(
        json['attendee'] as Map<String, dynamic>,
      ),
      savedImages: json['savedImages'] as int,
    );
  }
}

class EnrollmentBatchResult {
  const EnrollmentBatchResult({
    required this.enrolledCount,
    required this.totalSavedImages,
    required this.members,
  });

  final int enrolledCount;
  final int totalSavedImages;
  final List<EnrollmentMemberResult> members;

  factory EnrollmentBatchResult.fromJson(Map<String, dynamic> json) {
    return EnrollmentBatchResult(
      enrolledCount: json['enrolledCount'] as int,
      totalSavedImages: json['totalSavedImages'] as int,
      members: (json['members'] as List<dynamic>)
          .map(
            (entry) => EnrollmentMemberResult.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.signalLabel,
    required this.signalValue,
    required this.matchLabel,
    required this.matchValue,
    required this.imageUrl,
    required this.accent,
  });

  final String title;
  final String body;
  final String signalLabel;
  final String signalValue;
  final String matchLabel;
  final String matchValue;
  final String imageUrl;
  final Color accent;
}

String formatClock(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
