import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/dev_preview_flags.dart';
import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../navigation_tools_and_animation/app_tab_index.dart';
import '../../navigation_tools_and_animation/fade_page_route.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
import '../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../widgets_custom_lotties/game_toast.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_screen.dart';
import 'feedback_screen.dart';
import 'personal_details_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.profile,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _logout(BuildContext context) async {
    await context.read<UserStatsController>().signOut();

    GameToast.show(
      context,
      title: 'Logged out',
      message: 'Your session and cached progress were cleared safely.',
      icon: Icons.logout_rounded,
      accent: const Color(0xFFFFB084),
    );

    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(
        builder: (_) => const AuthScreen(mode: AuthMode.login),
      ),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    UserStatsController controller,
    User user,
  ) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (pickedFile == null) {
        return;
      }

      setState(() => _isUploadingPhoto = true);
      final bytes = await pickedFile.readAsBytes();
      final avatarUrl = await SupabaseService.instance.uploadProfileAvatar(
        userId: user.id,
        bytes: bytes,
        fileExtension: _fileExtensionForUpload(
          pickedFile.name,
          fallbackBytes: bytes,
        ),
      );

      // Cloud storage may not be configured. Rather than dead-ending, fall
      // back to the picked file's own path so the photo still shows on this
      // device — the picture works either way.
      final uploaded = avatarUrl != null && avatarUrl.isNotEmpty;
      final resolvedUrl = uploaded ? avatarUrl : pickedFile.path;

      if (uploaded) {
        await SupabaseService.instance.updateProfileAvatarUrl(
          userId: user.id,
          avatarUrl: avatarUrl,
        );
      }
      final result = await controller.updateProfilePhoto(resolvedUrl);
      if (!context.mounted) {
        return;
      }

      GameToast.show(
        context,
        title: uploaded ? 'Photo updated' : 'Photo set on this device',
        message: uploaded
            ? result.syncState.message
            : 'Cloud storage is unavailable, so it is saved locally only.',
        icon: Icons.camera_alt_rounded,
        accent: uploaded
            ? const Color(0xFF4BD2A3)
            : const Color(0xFFFFB084),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      GameToast.show(
        context,
        title: 'Upload failed',
        message: '$error',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFFF8E72),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  String _fileExtensionForUpload(
    String filename, {
    required Uint8List fallbackBytes,
  }) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filename.length - 1) {
      return filename.substring(dotIndex + 1).toLowerCase();
    }
    if (fallbackBytes.length > 3 &&
        fallbackBytes[0] == 0x89 &&
        fallbackBytes[1] == 0x50 &&
        fallbackBytes[2] == 0x4E &&
        fallbackBytes[3] == 0x47) {
      return 'png';
    }
    return 'jpg';
  }

  String _personalDetailsSummary(UserStats stats) {
    if (!stats.hasCompletedPersonalDetails) {
      return 'Add your age and how you describe yourself.';
    }
    final parts = <String>[
      if (stats.ageBand != AgeBand.undisclosed) stats.ageBand.label,
      if (stats.gender != GenderIdentity.undisclosed) stats.gender.label,
    ];
    return parts.isEmpty ? 'Not shared' : parts.join(' • ');
  }

  Future<void> _editPersonalDetails(
    BuildContext context,
    UserStats stats,
  ) async {
    HapticFeedback.lightImpact();
    await PersonalDetailsSheet.show(
      context,
      ageBand: stats.ageBand,
      gender: stats.gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserStatsController, AppSettingsController>(
      builder: (context, controller, settings, _) {
        final stats = controller.stats;
            final profileData = snapshot.data;
            final avatarUrl = stats.profileImageUrl.isNotEmpty
                ? stats.profileImageUrl
                : remoteAvatarUrl;
                    ),
                        _ProfileHero(
                          stats: stats,
                          avatarUrl: avatarUrl,
                          isUploadingPhoto: _isUploadingPhoto,
                          onUploadTap: user == null
                              ? null
                              : () => _pickAndUploadPhoto(
                                  context,
                                  controller,
                                  user,
                                ),
                        ),
                        _ProfileInsightCard(stats: stats),
                        const SizedBox(height: 12),
                            value: settings.notificationsEnabled,
                            activeThumbColor: const Color(0xFF4BD2A3),
                            onChanged: (value) async {
                              await settings.setNotificationsEnabled(value);
                          subtitle:
                              'Live across buttons, nav, and reward effects.',
                            value: settings.soundEnabled,
                            activeThumbColor: const Color(0xFF4BD2A3),
                            onChanged: (value) async {
                              await settings.setSoundEnabled(value);
                        _SettingsCard(
                          title: 'About You',
                          subtitle: _personalDetailsSummary(stats),
                          icon: Icons.badge_rounded,
                          onTap: () => _editPersonalDetails(context, stats),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFB7F7D7),
                          ),
                        ),
                        const SizedBox(height: 12),
                              color: Color(0xFFB7F7D7),
                            ),
                        ),
                        if (kFeedbackEnabled) ...[
                          const SizedBox(height: 12),
                          _SettingsCard(
                            title: 'Send Feedback',
                            subtitle: 'Report a bug, share an idea, or say hi.',
                            icon: Icons.mail_rounded,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FeedbackScreen(),
                                ),
                              );
                            },
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFB7F7D7),
                            ),
                          ),
                        ],

                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33F55353),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                  style: GoogleFonts.baloo2(
                        ),
                    ),
              ),
        );
      },
    );
  }
}

  const _ProfileHero({
    required this.stats,
    required this.avatarUrl,
    required this.isUploadingPhoto,
    required this.onUploadTap,
  });

  final UserStats stats;
  final String avatarUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122D24), Color(0xFF1A4133)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 420;
          final avatar = Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4BD2A3), Color(0xFF9EF0D0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4BD2A3).withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF091914),
                    ),
                    child: ClipOval(
                      child: avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF4BD2A3),
                              size: 40,
                            )
                          : _AvatarImage(url: avatarUrl),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: onUploadTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4BD2A3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF091914),
                        width: 3,
                      ),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF092018),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF092018),
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                stats.username,
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.baloo2(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats.levelTitle,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFFB7F7D7),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a profile photo to make the app feel more like your personal finance hub.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(children: [avatar, const SizedBox(height: 16), copy]);
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileInsightCard extends StatelessWidget {
  const _ProfileInsightCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 620;
          final metrics = [
            _InsightMetric(
              label: 'Gold',
              value: '${stats.gold}',
              icon: Icons.account_balance_wallet_rounded,
              accent: const Color(0xFFF2C66D),
            ),
            _InsightMetric(
              label: 'Literacy',
              value: '${stats.literacyPoints}',
              icon: Icons.school_rounded,
              accent: const Color(0xFF69C6FF),
            ),
            _InsightMetric(
              label: 'Level',
              value: '${stats.level}',
              icon: Icons.workspace_premium_rounded,
              accent: const Color(0xFF4BD2A3),
            ),
          ];

          final metricRow = stacked
              ? Column(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      metrics[index],
                      if (index != metrics.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      Expanded(child: metrics[index]),
                      if (index != metrics.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                );

          return Column(
            children: [
              metricRow,
              const SizedBox(height: 14),
              const _BadgePreview(),
            ],
          );
        },
      ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4BD2A3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4BD2A3).withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF2C66D).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFF2C66D),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Badge Showcase',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reserved for earned finance badges.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w600,
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

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
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

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4BD2A3).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF4BD2A3)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
        ),
        trailing: trailing,
      ),
    );
  }
}

  const _AdminCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.admin_panel_settings, color: Colors.amber),
        ),
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Moderation and account controls.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
        ),
        onTap: onTap,
      ),
    );
  }
}

  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.profileTileBackground,
          repeat: ImageRepeat.repeat,
          filterQuality: FilterQuality.none,
        ),
        Container(color: const Color(0xFF071711).withValues(alpha: 0.50)),
      ],
    );
  }

/// Renders a profile photo from either a remote URL or a local file path,
/// so the picture still shows when cloud storage isn't available.
class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url});

  final String url;

  static const Widget _placeholder = Icon(
    Icons.person_rounded,
    color: Color(0xFF4BD2A3),
    size: 40,
  );

  @override
  Widget build(BuildContext context) {
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    if (isRemote) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _placeholder,
      );
    }
    if (kIsWeb) {
      return _placeholder;
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => _placeholder,
    );
  }
}
