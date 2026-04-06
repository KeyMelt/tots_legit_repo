part of '../main.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AttendeeRepository extends ChangeNotifier {
  Future<List<AttendeeSummary>> listAttendees({
    HistoryFilter filter = HistoryFilter.all,
  });

  Future<AttendeeDetail> getAttendeeDetail(String id);

  Future<List<AttendeeDetail>> listMemberProfiles();

  Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required ScanSource source,
    bool preview = false,
  });

  Future<EnrollmentBatchResult> enrollMembers({
    required List<EnrollmentMemberDraft> members,
  });

  Future<ApprovedGuestsConfig> getApprovedGuests();

  Future<ApprovedGuestsConfig> saveApprovedGuests(List<String> names);
}

class FastApiAttendeeRepository extends AttendeeRepository {
  FastApiAttendeeRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(_normalizeBaseUrl(baseUrl ?? defaultApiBaseUrl()));

  final http.Client _client;
  final Uri _baseUri;

  @override
  Future<List<AttendeeSummary>> listAttendees({
    HistoryFilter filter = HistoryFilter.all,
  }) async {
    final response = await _sendRequest(
      () => _client.get(
        _buildUri('/api/attendees', queryParameters: {'filter': filter.name}),
      ),
    );
    final payload = _decodeJson(response.body);
    if (payload is! List) {
      throw const RepositoryException(
        'Unexpected history payload from the backend.',
      );
    }
    return payload
        .map(
          (entry) =>
              AttendeeSummary.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  @override
  Future<AttendeeDetail> getAttendeeDetail(String id) async {
    final response = await _sendRequest(
      () => _client.get(_buildUri('/api/attendees/$id')),
    );
    final payload = _decodeJson(response.body);
    if (payload is! Map) {
      throw const RepositoryException(
        'Unexpected attendee payload from the backend.',
      );
    }
    return AttendeeDetail.fromJson(Map<String, dynamic>.from(payload));
  }

  @override
  Future<List<AttendeeDetail>> listMemberProfiles() async {
    final response = await _sendRequest(
      () => _client.get(_buildUri('/api/member-profiles')),
    );
    final payload = _decodeJson(response.body);
    if (payload is! List) {
      throw const RepositoryException(
        'Unexpected member-profile payload from the backend.',
      );
    }
    return payload
        .map(
          (entry) =>
              AttendeeDetail.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  @override
  Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required ScanSource source,
    bool preview = false,
  }) async {
    final mediaType = _guessImageMediaType(imageBytes);
    final request = http.MultipartRequest('POST', _buildUri('/api/scans'))
      ..fields['source'] = source.wireValue
      ..fields['preview'] = preview.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename:
              'scan-${DateTime.now().millisecondsSinceEpoch}.${_extensionForMediaType(mediaType)}',
          contentType: mediaType,
        ),
      );

    final response = await _sendMultipartRequest(request);
    final payload = _decodeJson(response.body);
    if (payload is! Map) {
      throw const RepositoryException(
        'Unexpected scan payload from the backend.',
      );
    }

    if (!preview) {
      notifyListeners();
    }
    return ScanResult.fromJson(Map<String, dynamic>.from(payload));
  }

  @override
  Future<EnrollmentBatchResult> enrollMembers({
    required List<EnrollmentMemberDraft> members,
  }) async {
    final manifest = jsonEncode({
      'members': members
          .map(
            (member) => {
              'label': member.label,
              'status': member.status.wireValue,
            },
          )
          .toList(),
    });
    final request = http.MultipartRequest('POST', _buildUri('/api/enrollments'))
      ..fields['manifest'] = manifest;

    for (var memberIndex = 0; memberIndex < members.length; memberIndex += 1) {
      final member = members[memberIndex];
      for (
        var imageIndex = 0;
        imageIndex < member.images.length;
        imageIndex += 1
      ) {
        final mediaType = _guessImageMediaType(member.images[imageIndex]);
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            member.images[imageIndex],
            filename:
                'member_${memberIndex}__frame_$imageIndex.${_extensionForMediaType(mediaType)}',
            contentType: mediaType,
          ),
        );
      }
    }

    final response = await _sendMultipartRequest(request);
    final payload = _decodeJson(response.body);
    if (payload is! Map) {
      throw const RepositoryException(
        'Unexpected enrollment payload from the backend.',
      );
    }

    notifyListeners();
    return EnrollmentBatchResult.fromJson(Map<String, dynamic>.from(payload));
  }

  @override
  Future<ApprovedGuestsConfig> getApprovedGuests() async {
    final response = await _sendRequest(
      () => _client.get(_buildUri('/api/approved-guests')),
    );
    final payload = _decodeJson(response.body);
    if (payload is! Map) {
      throw const RepositoryException(
        'Unexpected approved-guest payload from the backend.',
      );
    }
    return ApprovedGuestsConfig.fromJson(Map<String, dynamic>.from(payload));
  }

  @override
  Future<ApprovedGuestsConfig> saveApprovedGuests(List<String> names) async {
    final response = await _sendRequest(
      () => _client.put(
        _buildUri('/api/approved-guests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'names': names}),
      ),
    );
    final payload = _decodeJson(response.body);
    if (payload is! Map) {
      throw const RepositoryException(
        'Unexpected approved-guest payload from the backend.',
      );
    }
    notifyListeners();
    return ApprovedGuestsConfig.fromJson(Map<String, dynamic>.from(payload));
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    return _baseUri.replace(
      path:
          '${_baseUri.path}${path.startsWith('/') ? path.substring(1) : path}',
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() requestBuilder,
  ) async {
    try {
      final response = await requestBuilder();
      _throwIfFailed(response.statusCode, response.body);
      return response;
    } on RepositoryException {
      rethrow;
    } catch (_) {
      throw RepositoryException(
        'Cannot reach the FastAPI backend at $_baseUri. '
        'Start it with `.venv/bin/python -m uvicorn main:app --reload`.',
      );
    }
  }

  Future<http.Response> _sendMultipartRequest(
    http.MultipartRequest request,
  ) async {
    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      _throwIfFailed(response.statusCode, response.body);
      return response;
    } on RepositoryException {
      rethrow;
    } catch (_) {
      throw RepositoryException(
        'Cannot reach the FastAPI backend at $_baseUri. '
        'Start it with `.venv/bin/python -m uvicorn main:app --reload`.',
      );
    }
  }

  void _throwIfFailed(int statusCode, String body) {
    if (statusCode < 400) {
      return;
    }

    final payload = _decodeJson(body);
    if (payload case {'detail': final String detail}) {
      throw RepositoryException(detail);
    }
    throw RepositoryException(
      'Backend request failed with status $statusCode.',
    );
  }

  Object? _decodeJson(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      throw const RepositoryException('Backend returned invalid JSON.');
    }
  }
}

MediaType _guessImageMediaType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return MediaType('image', 'png');
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return MediaType('image', 'jpeg');
  }

  return MediaType('image', 'jpeg');
}

String _extensionForMediaType(MediaType mediaType) {
  return switch (mediaType.subtype) {
    'png' => 'png',
    _ => 'jpg',
  };
}

String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) {
    return configured;
  }

  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
      return Uri.base.origin;
    }
    return 'http://127.0.0.1:8000';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:8000',
    _ => 'http://127.0.0.1:8000',
  };
}

String _normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'http://127.0.0.1:8000/';
  }
  return trimmed.endsWith('/') ? trimmed : '$trimmed/';
}
