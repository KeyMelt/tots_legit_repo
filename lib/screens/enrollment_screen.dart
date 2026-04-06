part of '../main.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key, required this.repository});

  final AttendeeRepository repository;

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_EnrollmentDraftController> _drafts = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _drafts.add(_EnrollmentDraftController());
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _captureFrames(_EnrollmentDraftController draft) async {
    if (_submitting) {
      return;
    }

    final capturedFrames = await showDialog<List<Uint8List>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FrameCaptureDialog(),
    );
    if (!mounted || capturedFrames == null || capturedFrames.isEmpty) {
      return;
    }

    setState(() => draft.images.addAll(capturedFrames));
  }

  Future<void> _pickImages(_EnrollmentDraftController draft) async {
    if (_submitting) {
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final pickedBytes = <Uint8List>[];
    for (final file in files) {
      pickedBytes.add(await file.readAsBytes());
    }
    setState(() => draft.images.addAll(pickedBytes));
  }

  void _addDraft() {
    setState(() => _drafts.add(_EnrollmentDraftController()));
  }

  void _removeDraft(_EnrollmentDraftController draft) {
    if (_drafts.length == 1) {
      return;
    }
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  Future<void> _submitEnrollment() async {
    final memberDrafts = <EnrollmentMemberDraft>[];
    for (final draft in _drafts) {
      final label = draft.labelController.text.trim();
      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a label for every unknown person.'),
          ),
        );
        return;
      }
      if (draft.images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add at least one frame for $label.')),
        );
        return;
      }
      memberDrafts.add(
        EnrollmentMemberDraft(
          label: label,
          images: List<Uint8List>.from(draft.images),
          status: draft.status,
        ),
      );
    }

    setState(() => _submitting = true);
    try {
      final result = await widget.repository.enrollMembers(members: memberDrafts);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppPalette.surfaceContainer,
          title: Text(
            'Enrollment Complete',
            style: headlineStyle(
              22,
              color: AppPalette.onSurface,
              weight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Enrolled ${result.enrolledCount} member(s) with ${result.totalSavedImages} saved frame(s). '
            'Approved status is now driven by the guest list and the selection on each card.',
            style: bodyStyle(
              14,
              color: AppPalette.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on RepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to enroll these members right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D121B), AppPalette.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Enroll Unknown Members',
                        style: headlineStyle(
                          24,
                          color: AppPalette.onSurface,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceContainer,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create one card per unknown person.',
                              style: headlineStyle(
                                18,
                                color: AppPalette.onSurface,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use Capture Frames to open the live camera, collect multiple shots for one person, then label them. The approval selection controls whether that person is added to the approved guest list or kept as rejected/manual review.',
                              style: bodyStyle(
                                14,
                                color: AppPalette.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._drafts.map(_buildDraftCard),
                      const SizedBox(height: 6),
                      SecondaryPillButton(
                        label: 'ADD ANOTHER PERSON',
                        icon: Icons.person_add_rounded,
                        onPressed: () {
                          if (_submitting) {
                            return;
                          }
                          _addDraft();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryPillButton(
                  label: _submitting ? 'ENROLLING...' : 'SAVE ENROLLMENTS',
                  icon: Icons.how_to_reg_rounded,
                  onPressed: () {
                    if (_submitting) {
                      return;
                    }
                    unawaited(_submitEnrollment());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(_EnrollmentDraftController draft) {
    final index = _drafts.indexOf(draft);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Unknown Person ${index + 1}',
                style: headlineStyle(
                  20,
                  color: AppPalette.onSurface,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_drafts.length > 1)
                IconButton(
                  onPressed: _submitting ? null : () => _removeDraft(draft),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.labelController,
            enabled: !_submitting,
            decoration: const InputDecoration(
              hintText: 'Enter the member label',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Approved list status',
            style: labelStyle(
              color: AppPalette.onSurfaceVariant,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Approved Guest'),
                selected: draft.status == AttendeeStatus.accepted,
                onSelected: _submitting
                    ? null
                    : (_) => setState(() {
                        draft.status = AttendeeStatus.accepted;
                      }),
              ),
              ChoiceChip(
                label: const Text('Rejected / Watchlist'),
                selected: draft.status == AttendeeStatus.rejected,
                onSelected: _submitting
                    ? null
                    : (_) => setState(() {
                        draft.status = AttendeeStatus.rejected;
                      }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (draft.images.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppPalette.surfaceContainerLowest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No frames captured yet.',
                style: bodyStyle(14, color: AppPalette.onSurfaceVariant),
              ),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: draft.images.length,
                separatorBuilder: (context, _) => const SizedBox(width: 10),
                itemBuilder: (context, imageIndex) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.memory(
                          draft.images[imageIndex],
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      draft.images.removeAt(imageIndex);
                                    });
                                  },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.68),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SecondaryPillButton(
                  label: 'CAPTURE FRAMES',
                  icon: Icons.photo_camera_rounded,
                  onPressed: () {
                    if (_submitting) {
                      return;
                    }
                    unawaited(_captureFrames(draft));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryPillButton(
                  label: 'UPLOAD FRAMES',
                  icon: Icons.collections_rounded,
                  onPressed: () {
                    if (_submitting) {
                      return;
                    }
                    unawaited(_pickImages(draft));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnrollmentDraftController {
  _EnrollmentDraftController()
      : labelController = TextEditingController(),
        status = AttendeeStatus.accepted;

  final TextEditingController labelController;
  final List<Uint8List> images = [];
  AttendeeStatus status;

  void dispose() {
    labelController.dispose();
  }
}

class _FrameCaptureDialog extends StatefulWidget {
  const _FrameCaptureDialog();

  @override
  State<_FrameCaptureDialog> createState() => _FrameCaptureDialogState();
}

class _FrameCaptureDialogState extends State<_FrameCaptureDialog> {
  CameraController? _controller;
  final List<Uint8List> _frames = [];
  bool _initializing = true;
  bool _capturing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _message = 'No camera is available on this device.';
        });
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
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _message = error.description ?? 'Camera access failed.';
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _message =
            'Camera capture is unavailable on this target. Use Chrome for live capture or upload saved images.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _message = 'Camera access failed.';
      });
    }
  }

  Future<void> _captureFrame() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) {
        return;
      }
      setState(() => _frames.add(bytes));
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.description ?? 'Unable to capture a frame.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppPalette.surfaceContainer,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Capture Frames',
                      style: headlineStyle(
                        22,
                        color: AppPalette.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Capture several clear images for one person before pressing Done.',
                style: bodyStyle(
                  14,
                  color: AppPalette.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFF081019)),
                    child: _initializing
                        ? const Center(child: CircularProgressIndicator())
                        : _controller != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_controller!),
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${_frames.length} frame(s) captured',
                                    textAlign: TextAlign.center,
                                    style: bodyStyle(
                                      14,
                                      color: AppPalette.onSurface,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _message ?? 'Camera unavailable.',
                                textAlign: TextAlign.center,
                                style: bodyStyle(
                                  15,
                                  color: AppPalette.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_frames.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _frames.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _frames[index],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              if (_frames.isNotEmpty) const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryPillButton(
                      label: 'CANCEL',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryPillButton(
                      label: _capturing ? 'CAPTURING...' : 'CAPTURE',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () {
                        if (_controller == null || _capturing) {
                          return;
                        }
                        unawaited(_captureFrame());
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryPillButton(
                      label: 'DONE',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(_frames),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
