import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

part 'data/app_models.dart';
part 'data/app_repository.dart';
part 'screens/app_flow.dart';
part 'screens/splash_screen.dart';
part 'screens/onboarding_screen.dart';
part 'screens/auth_screens.dart';
part 'screens/scan_screen.dart';
part 'screens/history_screen.dart';
part 'screens/identity_found_screen.dart';
part 'screens/enrollment_screen.dart';
part 'screens/settings_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const SyntheticEyeApp());
}

class SyntheticEyeApp extends StatelessWidget {
  const SyntheticEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Synthetic Eye',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.background,
        colorScheme: const ColorScheme.dark(
          primary: AppPalette.primary,
          surface: AppPalette.background,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppPalette.primary.withValues(alpha: 0.35),
            ),
          ),
          hintStyle: bodyStyle(
            14,
            color: AppPalette.onSurfaceVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      home: const AppFlow(),
    );
  }
}

Route<T> buildFadeRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, routeChild) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: routeChild,
      );
    },
  );
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.center_focus_weak_rounded, 'SCAN'),
      (Icons.receipt_long_rounded, 'HISTORY'),
      (Icons.settings_rounded, 'SETTINGS'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 96,
          color: AppPalette.background.withValues(alpha: 0.86),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppPalette.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index].$1,
                        size: 23,
                        color: selected
                            ? AppPalette.primary
                            : AppPalette.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].$2,
                        style: labelStyle(
                          color: selected
                              ? AppPalette.primary
                              : AppPalette.onSurfaceVariant.withValues(
                                  alpha: 0.55,
                                ),
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SyntheticHeader extends StatelessWidget {
  const SyntheticHeader({
    super.key,
    this.trailing,
    this.showAvatar = true,
    this.showSpark = false,
  });

  final Widget? trailing;
  final bool showAvatar;
  final bool showSpark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.visibility_outlined,
          color: AppPalette.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          'SYNTHETIC EYE',
          style: headlineStyle(
            18,
            color: AppPalette.primary,
            weight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        if (showSpark) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: AppPalette.onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
          if (showAvatar || trailing != null) const SizedBox(width: 12),
        ],
        if (trailing != null)
          trailing!
        else if (showAvatar)
          const ProfileAvatar(),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: AppNetworkImage(
          topAvatarUrl,
          fit: BoxFit.cover,
          fallback: Container(
            color: AppPalette.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Text(
              'SE',
              style: headlineStyle(
                11,
                color: AppPalette.primary,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPortal extends StatelessWidget {
  const OnboardingPortal({super.key, required this.page});

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: 320,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: page.accent.withValues(alpha: 0.09)),
            ),
          ),
          Container(
            width: 274,
            height: 274,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: page.accent.withValues(alpha: 0.18)),
            ),
          ),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.surfaceContainerLowest,
              border: Border.all(
                color: page.accent.withValues(alpha: 0.18),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.14),
                  blurRadius: 28,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    page.imageUrl,
                    fit: BoxFit.cover,
                    fallback: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B2A30), Color(0xFF050709)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          page.accent.withValues(alpha: 0.22),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: 54,
            child: PortalChip(
              label: page.signalLabel,
              value: page.signalValue,
              accent: page.accent,
            ),
          ),
          Positioned(
            left: -8,
            bottom: 68,
            child: PortalChip(
              label: page.matchLabel,
              value: page.matchValue,
              accent: page.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class PortalChip extends StatelessWidget {
  const PortalChip({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle(
              color: accent.withValues(alpha: 0.75),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: headlineStyle(
              14,
              color: AppPalette.onSurface,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanningFrame extends StatefulWidget {
  const ScanningFrame({super.key});

  @override
  State<ScanningFrame> createState() => _ScanningFrameState();
}

class _ScanningFrameState extends State<ScanningFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 304,
      height: 304,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 304,
            height: 304,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(42),
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.08),
                width: 2,
              ),
            ),
          ),
          const Positioned(
            top: -2,
            left: -2,
            child: ScanCorner(top: true, left: true),
          ),
          const Positioned(
            top: -2,
            right: -2,
            child: ScanCorner(top: true, left: false),
          ),
          const Positioned(
            bottom: -2,
            left: -2,
            child: ScanCorner(top: false, left: true),
          ),
          const Positioned(
            bottom: -2,
            right: -2,
            child: ScanCorner(top: false, left: false),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: SizedBox(
              width: 292,
              height: 292,
              child: Stack(
                children: [
                  const Positioned(
                    top: 58,
                    left: 38,
                    child: ScanDataMarker(
                      label: 'BIOMETRIC_POINT_012',
                      width: 72,
                    ),
                  ),
                  const Positioned(
                    right: 32,
                    bottom: 78,
                    child: ScanDataMarker(
                      label: 'NEURAL_SYNC_77%',
                      width: 86,
                      alignEnd: true,
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final y = _controller.value * 292;
                        return Stack(
                          children: [
                            Positioned(
                              top: y,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppPalette.primary.withValues(
                                        alpha: 0.95,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppPalette.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withValues(alpha: 0.8),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanCorner extends StatelessWidget {
  const ScanCorner({super.key, required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(32) : Radius.zero,
          topRight: top && !left ? const Radius.circular(32) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(32) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(32) : Radius.zero,
        ),
        border: Border(
          top: top
              ? const BorderSide(color: AppPalette.primary, width: 4)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppPalette.primary, width: 4)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppPalette.primary, width: 4)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppPalette.primary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class ScanDataMarker extends StatelessWidget {
  const ScanDataMarker({
    super.key,
    required this.label,
    required this.width,
    this.alignEnd = false,
  });

  final String label;
  final double width;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          height: 3,
          decoration: BoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: labelStyle(
            color: AppPalette.primary.withValues(alpha: 0.75),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class FloatingSquareAction extends StatelessWidget {
  const FloatingSquareAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: FrostedPanel(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: AppPalette.onSurface, size: 24),
        ),
      ),
    );
  }
}

class CaptureButton extends StatelessWidget {
  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isBusy = false,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool isBusy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !isBusy ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.primary,
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary.withValues(alpha: 0.35),
                blurRadius: 34,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppPalette.onPrimary.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppPalette.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: AppPalette.onPrimary,
                      size: 34,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.record, required this.onTap});

  final AttendeeSummary record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox.expand(
                      child: AppNetworkImage(
                        record.imageUrl,
                        fit: BoxFit.cover,
                        fallback: DecoratedBox(
                          decoration: BoxDecoration(
                            color: record.status == AttendeeStatus.unknown
                                ? AppPalette.surfaceContainerHighest
                                : AppPalette.surfaceContainerLow,
                          ),
                          child: Icon(
                            record.status == AttendeeStatus.unknown
                                ? Icons.help_center_rounded
                                : Icons.person_rounded,
                            color: record.status.color,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -6,
                    child: AttendeeStatusChip(
                      status: record.status,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.name,
                          overflow: TextOverflow.ellipsis,
                          style: headlineStyle(
                            16,
                            color: AppPalette.onSurface,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        record.timeLabel,
                        style: bodyStyle(
                          11,
                          color: AppPalette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.location,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle(
                            13,
                            color: AppPalette.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendeeStatusChip extends StatelessWidget {
  const AttendeeStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AttendeeStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: compact ? 0.92 : 0.16),
        borderRadius: BorderRadius.circular(compact ? 4 : 999),
      ),
      child: Text(
        status.badgeLabel,
        style: labelStyle(
          color: compact ? Colors.white : status.color,
          letterSpacing: compact ? 0.7 : 1.2,
        ),
      ),
    );
  }
}

class StatusMetricCard extends StatelessWidget {
  const StatusMetricCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle(
              color: AppPalette.onSurfaceVariant,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: headlineStyle(
              16,
              color: AppPalette.onSurface,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppPalette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: headlineStyle(
                    16,
                    color: AppPalette.onSurface,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: bodyStyle(
                    14,
                    color: AppPalette.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppPalette.onPrimary,
          backgroundColor: AppPalette.primary,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: headlineStyle(
                16,
                color: AppPalette.onPrimary,
                weight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppPalette.onSurface,
          backgroundColor: AppPalette.surfaceContainer,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: headlineStyle(
                14,
                color: AppPalette.onSurface,
                weight: FontWeight.w700,
                letterSpacing: 1.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppPalette.background.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    required this.fit,
    required this.fallback,
  });

  final String? url;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return fallback;
    }
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 120,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class GridBackground extends StatelessWidget {
  const GridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: GridPainter());
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 34.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppPalette {
  static const background = Color(0xFF0B0E14);
  static const primary = Color(0xFF81ECFF);
  static const primaryContainer = Color(0xFF00E3FD);
  static const tertiary = Color(0xFFAC89FF);
  static const onPrimary = Color(0xFF005762);
  static const onSurface = Color(0xFFECEEF6);
  static const onSurfaceVariant = Color(0xFFA9ABB3);
  static const onSecondaryContainer = Color(0xFFF7F7FF);
  static const onErrorContainer = Color(0xFFFFA8A3);
  static const secondaryContainer = Color(0xFF005BC0);
  static const error = Color(0xFFFF716C);
  static const errorContainer = Color(0xFF9F0519);
  static const accepted = Color(0xFF14B86A);
  static const rejected = Color(0xFFFF716C);
  static const unknown = Color(0xFFF4B740);
  static const surfaceContainer = Color(0xFF161A21);
  static const surfaceContainerLow = Color(0xFF10131A);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerHighest = Color(0xFF22262F);
}

TextStyle headlineStyle(
  double size, {
  required Color color,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0,
  double? height,
}) {
  return GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle bodyStyle(
  double size, {
  required Color color,
  FontWeight weight = FontWeight.w500,
  double letterSpacing = 0,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle labelStyle({required Color color, double letterSpacing = 1.4}) {
  return GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing,
  );
}

const topAvatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAu8LtAqsYCESoQV-UVx44frWqs5WotZi2SfNXPx2j9skrVWlXSDbFfyYh-0u7y4-gbnuMhp4bY8WByFqmy9_qaWWo1jMvNc0ts6-YrqS30yAbtDIMsgesQkWHbC42_K_nM8VFVZannG-gx__MWJo7AjF2rXn_7gor0-t500YVQ6uG1NUYSUWfVFxi0kOFP9105j-lve0Q10UrhzOVxjvNDxfS9Jwn9Nq_O8GEgT70OGxdIz9wQdi0-Z-tzEhHwIW0QIgvqTY5joqW0';

const onboardingPortalUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCl3ZjI-6HbuamYj_b0O7t-3dK1ibIs8LOZAh5Rt4n4bipajHR3TQK2MddGuEZRStV25CGQZQKKdSYjKrq6-dlgsaaOsq9CkAa-Nw6tEht-imvbJ6VytcTv3mWCKdyGuSEWOq5gtwqwyUhtoVF8a0EIUNiaTJuS9x3gipidRKZqfsseaxWfZbU3KDfuYgQPaPoYCzkUj5z0QwZVXPc6CGhwHSclHruTs8GvjJxsnVbExIftvDxhDqvVpIaOPYkQBeKK82ZeK2bYVr2g';

const eventPortalUrl =
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=900&q=80';

const crowdPortalUrl =
    'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=900&q=80';
