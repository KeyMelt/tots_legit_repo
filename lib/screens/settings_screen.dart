part of '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.onLogout,
  });

  final AttendeeRepository repository;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<AttendeeDetail> _profiles = const [];
  Set<String> _approvedIds = <String>{};
  bool _loading = true;
  bool _saving = false;

  bool get _hasChanges =>
      _profiles.any((profile) => _approvedIds.contains(profile.id) != (profile.status == AttendeeStatus.accepted));

  int get _approvedCount => _approvedIds.length;

  @override
  void initState() {
    super.initState();
    unawaited(_loadApprovalRegistry());
  }

  Future<void> _loadApprovalRegistry() async {
    setState(() => _loading = true);
    try {
      final profiles = await widget.repository.listMemberProfiles();
      if (!mounted) {
        return;
      }
      setState(() {
        _profiles = profiles;
        _approvedIds = profiles
            .where((profile) => profile.status == AttendeeStatus.accepted)
            .map((profile) => profile.id)
            .toSet();
      });
    } on RepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleApproval(AttendeeDetail profile, bool approved) {
    setState(() {
      if (approved) {
        _approvedIds.add(profile.id);
      } else {
        _approvedIds.remove(profile.id);
      }
    });
  }

  Future<void> _saveApprovalRegistry() async {
    setState(() => _saving = true);
    try {
      final approvedNames = _profiles
          .where((profile) => _approvedIds.contains(profile.id))
          .map((profile) => profile.name)
          .toList()
        ..sort();

      await widget.repository.saveApprovedGuests(approvedNames);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved approvals for ${approvedNames.length} people.',
          ),
        ),
      );
      await _loadApprovalRegistry();
    } on RepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _profiles.length - _approvedCount;

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
                      'SYSTEM PROFILE',
                      style: labelStyle(
                        color: AppPalette.primary.withValues(alpha: 0.6),
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Settings',
                      style: headlineStyle(
                        34,
                        color: AppPalette.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AppPalette.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Approval registry',
                                  style: headlineStyle(
                                    20,
                                    color: AppPalette.onSurface,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _loading || _saving
                                    ? null
                                    : () {
                                        unawaited(_loadApprovalRegistry());
                                      },
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Every saved person appears here. Toggle approval on or off, then save. Approved people scan as accepted. Saved people who are not approved scan as rejected.',
                            style: bodyStyle(
                              14,
                              color: AppPalette.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _RegistryMetricCard(
                                  label: 'SAVED PEOPLE',
                                  value: '${_profiles.length}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RegistryMetricCard(
                                  label: 'APPROVED',
                                  value: '$_approvedCount',
                                  valueColor: AppPalette.accepted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RegistryMetricCard(
                                  label: 'NOT APPROVED',
                                  value: '$pendingCount',
                                  valueColor: AppPalette.rejected,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_profiles.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceContainerLowest.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'No saved people yet. Enroll someone first, then manage approval here.',
                                style: bodyStyle(
                                  14,
                                  color: AppPalette.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            )
                          else
                            ..._profiles.map(_buildProfileTile),
                          const SizedBox(height: 12),
                          PrimaryPillButton(
                            label: _saving ? 'SAVING...' : 'SAVE APPROVALS',
                            icon: Icons.save_rounded,
                            onPressed: () {
                              if (_loading || _saving || !_hasChanges) {
                                return;
                              }
                              unawaited(_saveApprovalRegistry());
                            },
                          ),
                          if (!_hasChanges && !_loading)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'No unsaved approval changes.',
                                style: bodyStyle(
                                  13,
                                  color: AppPalette.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Instant match alerts',
                      subtitle:
                          'Live previews summarize approved, rejected, and unknown faces before capture.',
                    ),
                    const SizedBox(height: 20),
                    SecondaryPillButton(
                      label: 'LOG OUT',
                      icon: Icons.logout_rounded,
                      onPressed: widget.onLogout,
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

  Widget _buildProfileTile(AttendeeDetail profile) {
    final approved = _approvedIds.contains(profile.id);
    final statusColor = approved ? AppPalette.accepted : AppPalette.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainerLowest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: AppNetworkImage(
                profile.imageUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  color: AppPalette.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
                    color: statusColor,
                    size: 28,
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
                  profile.name,
                  style: headlineStyle(
                    18,
                    color: AppPalette.onSurface,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.role,
                  style: bodyStyle(
                    14,
                    color: AppPalette.onSurfaceVariant,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.location,
                  style: bodyStyle(
                    13,
                    color: AppPalette.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        approved ? 'APPROVED' : 'NOT APPROVED',
                        style: labelStyle(
                          color: statusColor,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        approved
                            ? 'Will scan as accepted.'
                            : 'Will scan as rejected.',
                        style: bodyStyle(
                          12,
                          color: AppPalette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: approved,
            activeThumbColor: AppPalette.accepted,
            activeTrackColor: AppPalette.accepted.withValues(alpha: 0.35),
            onChanged: _saving
                ? null
                : (value) {
                    _toggleApproval(profile, value);
                  },
          ),
        ],
      ),
    );
  }
}

class _RegistryMetricCard extends StatelessWidget {
  const _RegistryMetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainerLowest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle(
              color: AppPalette.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: headlineStyle(
              24,
              color: valueColor ?? AppPalette.onSurface,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
