part of '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository});

  final AttendeeRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;
  List<AttendeeSummary> _records = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_handleRepositoryUpdate);
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    widget.repository.removeListener(_handleRepositoryUpdate);
    super.dispose();
  }

  void _handleRepositoryUpdate() {
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final records = await widget.repository.listAttendees(
        filter: _selectedFilter,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _loading = false;
        _errorMessage = null;
      });
    } on RepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _records = const [];
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _records = const [];
        _loading = false;
        _errorMessage = 'Unable to load scan history from the backend.';
      });
    }
  }

  Future<void> _showAttendeeSheet(String attendeeId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return FutureBuilder<AttendeeDetail>(
          future: widget.repository.getAttendeeDetail(attendeeId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SizedBox(
                height: 260,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _detailErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: bodyStyle(
                        14,
                        color: AppPalette.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final detail = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppPalette.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: AppNetworkImage(
                            detail.imageUrl,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: AppPalette.surfaceContainerLow,
                              alignment: Alignment.center,
                              child: Icon(
                                detail.status == AttendeeStatus.unknown
                                    ? Icons.help_center_rounded
                                    : Icons.person_rounded,
                                color: detail.status.color,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.name,
                              style: headlineStyle(
                                24,
                                color: AppPalette.onSurface,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail.role,
                              style: bodyStyle(
                                15,
                                color: AppPalette.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AttendeeStatusChip(status: detail.status),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _DetailRow(label: 'Organization', value: detail.organization),
                  _DetailRow(label: 'Email', value: detail.email),
                  _DetailRow(label: 'Location', value: detail.location),
                  _DetailRow(label: 'Attendee status', value: detail.note),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C1119), AppPalette.background],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 104),
          child: Column(
            children: [
              const SyntheticHeader(),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'DATA RETRIEVAL',
                      style: labelStyle(
                        color: AppPalette.primary.withValues(alpha: 0.6),
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan History',
                      style: headlineStyle(
                        34,
                        color: AppPalette.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            color: AppPalette.onSurfaceVariant.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Filter identities...',
                            style: bodyStyle(
                              15,
                              color: AppPalette.onSurfaceVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: HistoryFilter.values.map((filter) {
                          final selected = filter == _selectedFilter;
                          return GestureDetector(
                            onTap: () {
                              if (_selectedFilter == filter) {
                                return;
                              }
                              setState(() => _selectedFilter = filter);
                              unawaited(_loadHistory());
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 10,
                                top: 10,
                                bottom: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppPalette.primary.withValues(alpha: 0.16)
                                    : AppPalette.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                filter.label,
                                style: bodyStyle(
                                  14,
                                  color: selected
                                      ? AppPalette.primary
                                      : AppPalette.onSurfaceVariant,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: bodyStyle(
                              15,
                              color: AppPalette.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      )
                    else if (_records.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'No attendee scans for this filter yet.',
                            style: bodyStyle(
                              15,
                              color: AppPalette.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._records.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HistoryCard(
                            record: record,
                            onTap: () => _showAttendeeSheet(record.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _detailErrorMessage(Object? error) {
    if (error is RepositoryException) {
      return error.message;
    }
    return 'Unable to load attendee details from the backend.';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: labelStyle(
              color: AppPalette.primary.withValues(alpha: 0.75),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: bodyStyle(
              14,
              color: AppPalette.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
