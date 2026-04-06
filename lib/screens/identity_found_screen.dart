part of '../main.dart';

class IdentityFoundScreen extends StatelessWidget {
  const IdentityFoundScreen({
    super.key,
    required this.result,
    required this.repository,
    required this.onSelectTab,
  });

  final ScanResult result;
  final AttendeeRepository repository;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final detail = result.detail;
    final status = result.status;
    final confidenceLabel = '${(result.confidence * 100).toStringAsFixed(2)}%';
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D121B), AppPalette.background],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 180,
              left: -90,
              child: GlowOrb(size: 260, color: status.color, opacity: 0.08),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        AttendeeStatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: status.color.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status == AttendeeStatus.accepted
                                  ? Icons.check_rounded
                                  : status == AttendeeStatus.rejected
                                  ? Icons.close_rounded
                                  : Icons.question_mark_rounded,
                              color: AppPalette.background,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      status.resultTitle,
                      textAlign: TextAlign.center,
                      style: headlineStyle(
                        32,
                        color: AppPalette.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MATCH CONFIDENCE: $confidenceLabel',
                      textAlign: TextAlign.center,
                      style: labelStyle(
                        color: status.color.withValues(alpha: 0.8),
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Container(
                        width: 196,
                        height: 196,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: status.color.withValues(alpha: 0.72),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: status.color.withValues(alpha: 0.18),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: ClipOval(
                            child: AppNetworkImage(
                              detail.imageUrl,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: AppPalette.surfaceContainerLow,
                                alignment: Alignment.center,
                                child: Icon(
                                  status == AttendeeStatus.unknown
                                      ? Icons.help_center_rounded
                                      : Icons.person_rounded,
                                  size: 52,
                                  color: status.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      child: Column(
                        children: [
                          Text(
                            detail.name,
                            textAlign: TextAlign.center,
                            style: headlineStyle(
                              30,
                              color: AppPalette.onSurface,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detail.role,
                            style: bodyStyle(
                              16,
                              color: AppPalette.onSurfaceVariant,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: StatusMetricCard(
                                  label: 'SOURCE',
                                  value: result.source.label,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatusMetricCard(
                                  label: 'CONFIDENCE',
                                  value: confidenceLabel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceContainerLowest
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ATTENDEE STATUS',
                                  style: labelStyle(
                                    color: status.color,
                                    letterSpacing: 1.7,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  detail.note,
                                  style: bodyStyle(
                                    14,
                                    color: AppPalette.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryPillButton(
                      label: status == AttendeeStatus.unknown
                          ? 'ENROLL UNKNOWN GUESTS'
                          : 'VIEW HISTORY',
                      icon: status == AttendeeStatus.unknown
                          ? Icons.person_add_alt_1_rounded
                          : Icons.receipt_long_rounded,
                      onPressed: () async {
                        if (status == AttendeeStatus.unknown) {
                          final enrolled = await Navigator.of(context)
                              .push<bool>(
                                buildFadeRoute(
                                  EnrollmentScreen(repository: repository),
                                ),
                              );
                          if (enrolled == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                          return;
                        }
                        onSelectTab(1);
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryPillButton(
                      label: status == AttendeeStatus.unknown
                          ? 'SCAN AGAIN'
                          : 'BACK TO SCAN',
                      icon: status == AttendeeStatus.unknown
                          ? Icons.camera_alt_rounded
                          : Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
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
}
