part of '../main.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.repository,
    required this.onLogout,
    required this.onOpenResult,
  });

  final AttendeeRepository repository;
  final VoidCallback onLogout;
  final ValueChanged<ScanResult> onOpenResult;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _previewInterval = Duration(milliseconds: 900);

  final ImagePicker _picker = ImagePicker();

  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _submitting = false;
  bool _illuminationOn = false;
  bool _previewProcessing = false;
  String? _cameraMessage;
  String _liveDetectionLabel = 'LIVE DETECTION OFFLINE';
  String _liveDetectionDetail = 'Preparing camera access for a live attendee scan.';
  Color _liveDetectionColor = AppPalette.onSurfaceVariant;
  DateTime _lastPreviewAttemptAt = DateTime.fromMillisecondsSinceEpoch(0);
  Uint8List? _latestPreviewFrameBytes;
  Timer? _webPreviewTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    _webPreviewTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null && controller.value.isStreamingImages) {
      unawaited(controller.stopImageStream().catchError((_) {}));
    }
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraMessage = 'Camera unavailable. Upload a photo from the device.';
            _liveDetectionLabel = 'NO CAMERA';
            _liveDetectionDetail = 'Live detection needs a camera source.';
            _liveDetectionColor = AppPalette.error;
          });
        }
        return;
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.macOS
            ? ImageFormatGroup.bgra8888
            : null,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _cameraMessage = null;
        _liveDetectionLabel = 'LIVE DETECTION STARTING';
        _liveDetectionDetail = 'Watching camera frames and checking faces locally.';
        _liveDetectionColor = AppPalette.primary;
      });
      await _startLivePreview(controller);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _cameraMessage =
              error.description ?? 'Camera unavailable. Upload a photo from the device.';
          _liveDetectionLabel = 'CAMERA ERROR';
          _liveDetectionDetail =
              error.description ?? 'Live detection could not access the camera.';
          _liveDetectionColor = AppPalette.error;
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _cameraMessage = defaultTargetPlatform == TargetPlatform.macOS
              ? 'The current camera plugin does not support macOS. Run `flutter run -d chrome` for live laptop detection.'
              : 'Camera unavailable. Upload a photo from the device.';
          _liveDetectionLabel = 'PLUGIN MISSING';
          _liveDetectionDetail = defaultTargetPlatform == TargetPlatform.macOS
              ? 'This package does not register a macOS camera implementation. Use the Chrome target on your laptop instead.'
              : 'The current platform does not expose the camera plugin.';
          _liveDetectionColor = defaultTargetPlatform == TargetPlatform.macOS
              ? AppPalette.unknown
              : AppPalette.error;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraMessage = 'Camera unavailable. Upload a photo from the device.';
          _liveDetectionLabel = 'CAMERA ERROR';
          _liveDetectionDetail = 'Live detection could not start on this device.';
          _liveDetectionColor = AppPalette.error;
        });
      }
    }
  }

  Future<void> _startLivePreview(CameraController controller) async {
    if (kIsWeb) {
      setState(() {
        _liveDetectionLabel = 'LIVE DETECTION STARTING';
        _liveDetectionDetail =
            'Using browser camera snapshots for live face checks.';
        _liveDetectionColor = AppPalette.primary;
      });
      _startWebPreviewPolling(controller);
      return;
    }

    if (controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream((image) {
        if (!mounted || _submitting || _previewProcessing) {
          return;
        }
        final now = DateTime.now();
        if (now.difference(_lastPreviewAttemptAt) < _previewInterval) {
          return;
        }
        _lastPreviewAttemptAt = now;
        unawaited(_processPreviewFrame(image));
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _liveDetectionLabel = 'LIVE PREVIEW OFF';
          _liveDetectionDetail = error.description ??
              'This platform does not support streaming camera frames.';
          _liveDetectionColor = AppPalette.unknown;
        });
      }
    }
  }

  void _startWebPreviewPolling(CameraController controller) {
    _webPreviewTimer?.cancel();
    _webPreviewTimer = Timer.periodic(_previewInterval, (_) {
      if (!mounted || _submitting || _previewProcessing) {
        return;
      }
      if (!controller.value.isInitialized || controller.value.isTakingPicture) {
        return;
      }
      unawaited(_captureWebPreviewSnapshot(controller));
    });
  }

  Future<void> _captureWebPreviewSnapshot(CameraController controller) async {
    _previewProcessing = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return;
      }
      await _processPreviewBytes(bytes);
    } on CameraException {
      if (mounted) {
        setState(() {
          _liveDetectionLabel = 'WEB CAPTURE ERROR';
          _liveDetectionDetail =
              'The browser camera snapshot could not be captured.';
          _liveDetectionColor = AppPalette.error;
        });
      }
    } finally {
      _previewProcessing = false;
    }
  }

  Future<void> _processPreviewFrame(CameraImage image) async {
    _previewProcessing = true;
    try {
      final frameBytes = await _encodePreviewFrame(image);
      if (frameBytes == null || frameBytes.isEmpty) {
        if (mounted) {
          setState(() {
            _liveDetectionLabel = 'UNSUPPORTED FORMAT';
            _liveDetectionDetail =
                'The current camera stream format cannot be analyzed live.';
            _liveDetectionColor = AppPalette.unknown;
          });
        }
        return;
      }
      await _processPreviewBytes(frameBytes);
    } on RepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _liveDetectionLabel = 'BACKEND OFFLINE';
          _liveDetectionDetail = error.message;
          _liveDetectionColor = AppPalette.error;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveDetectionLabel = 'PREVIEW ERROR';
          _liveDetectionDetail =
              'Live detection could not process the current frame.';
          _liveDetectionColor = AppPalette.error;
        });
      }
    } finally {
      _previewProcessing = false;
    }
  }

  Future<void> _processPreviewBytes(Uint8List frameBytes) async {
    _latestPreviewFrameBytes = frameBytes;
    final result = await widget.repository.submitScan(
      imageBytes: frameBytes,
      source: ScanSource.camera,
      preview: true,
    );
    if (!mounted) {
      return;
    }
    _applyPreviewResult(result);
  }

  Future<Uint8List?> _encodePreviewFrame(CameraImage image) async {
    if (image.format.group == ImageFormatGroup.jpeg && image.planes.isNotEmpty) {
      return Uint8List.fromList(image.planes.first.bytes);
    }

    if (image.format.group != ImageFormatGroup.bgra8888 || image.planes.isEmpty) {
      return null;
    }

    final plane = image.planes.first;
    final buffer = await ImmutableBuffer.fromUint8List(plane.bytes);
    final descriptor = ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      rowBytes: plane.bytesPerRow,
      pixelFormat: PixelFormat.bgra8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return byteData?.buffer.asUint8List();
  }

  void _applyPreviewResult(ScanResult result) {
    final summary = result.summary;
    final detail = result.detail;
    late final String label;
    late final String description;
    late final Color color;

    if (summary != null && summary.faceCount > 1) {
      final knownNames = summary.matches
          .where((match) => match.name != 'Unknown')
          .map((match) => match.name)
          .take(3)
          .toList();
      label =
          '${summary.faceCount} FACES | ${summary.acceptedCount} APPROVED | ${summary.unknownCount} UNKNOWN';
      description = [
        if (knownNames.isNotEmpty) 'Matched: ${knownNames.join(', ')}.',
        if (summary.rejectedCount > 0)
          '${summary.rejectedCount} on file but not approved.',
        if (summary.unknownCount > 0)
          '${summary.unknownCount} unknown. Add one enrollment card per person.',
      ].join(' ');
      color = summary.status.color;
    } else if (detail.note.startsWith('No face was detected')) {
      label = 'NO FACE DETECTED';
      description = 'Move closer, face the camera directly, and keep one person inside the frame.';
      color = AppPalette.unknown;
    } else {
      switch (result.status) {
        case AttendeeStatus.accepted:
          label = 'KNOWN: ${detail.name.toUpperCase()}';
          description = 'Accepted attendee detected with ${(result.confidence * 100).toStringAsFixed(1)}% confidence.';
          color = AppPalette.accepted;
        case AttendeeStatus.rejected:
          label = 'REJECTED: ${detail.name.toUpperCase()}';
          description = 'A record exists, but this attendee is not on the accepted list.';
          color = AppPalette.rejected;
        case AttendeeStatus.unknown:
          label = 'UNKNOWN GUEST';
          description = detail.note;
          color = AppPalette.unknown;
      }
    }

    setState(() {
      _liveDetectionLabel = label;
      _liveDetectionDetail = description;
      _liveDetectionColor = color;
    });
  }

  Future<void> _captureLiveImage() async {
    if (!_cameraReady || _submitting) {
      return;
    }

    final bytes = _latestPreviewFrameBytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wait a moment for the live preview to capture a frame.'),
          ),
        );
      }
      return;
    }

    await _submitScan(bytes, ScanSource.camera);
  }

  Future<void> _pickFromGallery() async {
    if (_submitting) {
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    await _submitScan(bytes, ScanSource.gallery);
  }

  Future<void> _submitScan(Uint8List bytes, ScanSource source) async {
    setState(() => _submitting = true);
    try {
      final result = await widget.repository.submitScan(
        imageBytes: bytes,
        source: source,
      );
      if (!mounted) {
        return;
      }
      widget.onOpenResult(result);
    } on RepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to process this scan right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surfaceContainer,
        title: Text(
          'Help',
          style: headlineStyle(
            20,
            color: AppPalette.onSurface,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'The laptop app now runs live preview checks against the backend. It can summarize groups in one frame, but the detailed capture result screen is still clearest when you save one person at a time. Unknown results can be enrolled afterward with multiple frames per person.',
          style: bodyStyle(14, color: AppPalette.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<ProfileMenuAction>(
      onSelected: (action) {
        if (action == ProfileMenuAction.help) {
          _showHelp();
        } else {
          widget.onLogout();
        }
      },
      color: AppPalette.surfaceContainer,
      itemBuilder: (context) => const [
        PopupMenuItem(value: ProfileMenuAction.help, child: Text('Help')),
        PopupMenuItem(value: ProfileMenuAction.logout, child: Text('Log out')),
      ],
      child: const ProfileAvatar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCapture =
        _cameraReady && !_submitting && _latestPreviewFrameBytes != null;
    return Stack(
      children: [
        Positioned.fill(
          child: _cameraReady && _cameraController != null
              ? CameraPreview(_cameraController!)
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0E1118), Color(0xFF252C33)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        _cameraMessage ??
                            'Preparing camera access for a live attendee scan.',
                        textAlign: TextAlign.center,
                        style: bodyStyle(
                          16,
                          color: AppPalette.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(color: Colors.black.withValues(alpha: 0.38)),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xAA0B0E14),
                    Colors.transparent,
                    Color(0xE60B0E14),
                  ],
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _illuminationOn ? 1 : 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.95,
                  colors: [
                    Colors.white.withValues(alpha: 0.82),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.04, 0.32, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SyntheticHeader(
                  showAvatar: false,
                  trailing: _buildProfileMenu(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 112),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ScanningFrame(),
                      const SizedBox(height: 26),
                      FrostedPanel(
                        borderRadius: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _submitting
                                      ? AppPalette.primary
                                      : _liveDetectionColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_submitting
                                              ? AppPalette.primary
                                              : _liveDetectionColor)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _submitting
                                    ? 'PROCESSING SCAN...'
                                    : _liveDetectionLabel,
                                style: headlineStyle(
                                  14,
                                  color: _submitting
                                      ? AppPalette.primary
                                      : _liveDetectionColor,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          _cameraReady
                              ? _liveDetectionDetail
                              : 'Live camera access is unavailable. Upload a photo from the device to continue.',
                          textAlign: TextAlign.center,
                          style: bodyStyle(
                            17,
                            color: AppPalette.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 126,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingSquareAction(
                icon: Icons.photo_library_outlined,
                onTap: _pickFromGallery,
                active: !_submitting,
              ),
              CaptureButton(
                onPressed: _captureLiveImage,
                enabled: canCapture,
                isBusy: _submitting,
              ),
              FloatingSquareAction(
                icon: _illuminationOn
                    ? Icons.highlight_rounded
                    : Icons.flash_on_rounded,
                onTap: () => setState(() => _illuminationOn = !_illuminationOn),
                active: !kIsWeb,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
