import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../config/dev_preview_flags.dart';
import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../controllers_that_updates_stats/money_habit_controller.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../navigation_tools_and_animation/app_tab_index.dart';
import '../../navigation_tools_and_animation/fade_page_route.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/cloud_sync_banner.dart';
import '../../widgets_custom_lotties/achievement_celebration.dart';
import '../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../widgets_custom_lotties/habit_progress_grids.dart';
import '../../widgets_custom_lotties/game_toast.dart';
import '../../widgets_custom_lotties/idle_hover_icon.dart';
import '../../widgets_custom_lotties/vivid_backdrop.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_screen.dart';
import '../onboarding/tutorial_screen.dart';
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

      // cloud storage might not be set up. instead of dead ending, fall back
      // to the picked file's own path so the photo still shows on this
      // device. works either way from the users point of view
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
        accent: uploaded ? const Color(0xFF4BD2A3) : const Color(0xFFFFB084),
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

  /// Replays the guided tour on purpose.
  ///
  /// Raises a flag on [AppSettingsController] rather than pushing a screen.
  /// The tour spotlights the real tabs, which means it has to be drawn by the
  /// navigation shell — and Profile is one of the screens inside that shell,
  /// so it asks rather than acts. The shell is already listening.
  ///
  /// Falls back to the standalone deck when Profile is *not* hosted as a tab
  /// (it can be pushed as its own route), because there are no tabs to point
  /// at in that case and a spotlight with nothing under it is worse than a
  /// description.
  Future<void> _replayTutorial(BuildContext context) async {
    HapticFeedback.lightImpact();

    if (widget.onNavSelected != null) {
      context.read<AppSettingsController>().requestTutorialReplay();
      return;
    }

    final jumpTab = await TutorialScreen.show(context);
    if (!mounted || jumpTab == null) {
      return;
    }
    widget.onNavSelected?.call(jumpTab);
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
        final user = SupabaseService.instance.currentUser;
            final profileData = snapshot.data;
            final avatarUrl = stats.profileImageUrl.isNotEmpty
                ? stats.profileImageUrl
                : remoteAvatarUrl;
              backgroundColor: AppTheme.deepForest,
                    ),
                        const CloudSyncBanner(),
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
                        _BadgeShowcase(stats: stats),
                        const SizedBox(height: 12),
                        const _MoneyHabitsProfileCard(),
                        const SizedBox(height: 12),
                        const _FriendsCard(),
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
                          title: 'Music',
                          subtitle:
                              'A calm loop under the app. Separate from sound.',
                          icon: Icons.music_note_rounded,
                          trailing: Switch.adaptive(
                            value: settings.musicEnabled,
                            activeThumbColor: const Color(0xFF4BD2A3),
                            onChanged: (value) async {
                              HapticFeedback.lightImpact();
                              await settings.setMusicEnabled(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(
                          title: 'Replay Tutorial',
                          subtitle:
                              'Take Buddy\'s tour of every page again.',
                          icon: Icons.school_rounded,
                          onTap: () => _replayTutorial(context),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFB7F7D7),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          // Masked, never the full address.
                          //
                          // this app is for kids, and a profile screen is
                          // one of the most screenshotted bits of any app.
                          // printing a full email there puts a real contact
                          // detail into every screenshot and
                          // every over-the-shoulder glance. The masked form
                          // still answers the only question this row exists to
                          // answer: which account am I signed into.
                          subtitle: user?.email == null
                              ? 'Signed in as ${stats.username}.'
                              : _maskEmail(user!.email!),
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
                                  style: GoogleFonts.pixelifySans(
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
                style: GoogleFonts.pixelifySans(
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

/// One earnable badge. Every tier is derived from progress the app *already*
/// records — endings reached, skins unlocked, lessons completed, level — so
/// nothing here needs a parallel achievement-tracking system to stay honest.
@immutable
class _Badge {
  const _Badge({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.earned,
    required this.detail,
  });

  /// Stable key used to remember whether its unlock popup already played.
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool earned;
  final String detail;
}

/// The profile badge shelf.
///
/// Doubles as the "show skins more" surface: a skins-collected badge sits
/// alongside the story/learning ones, so the customise grid isn't the only
/// place unlocked skins are acknowledged.
class _BadgeShowcase extends StatefulWidget {
  const _BadgeShowcase({required this.stats});

  final UserStats stats;

  @override
  State<_BadgeShowcase> createState() => _BadgeShowcaseState();
}

class _BadgeShowcaseState extends State<_BadgeShowcase> {
  UserStats get stats => widget.stats;

  /// Opens the celebration for a badge the player tapped.
  ///
  /// Deliberately **not** automatic. An earlier version fired this from
  /// `initState`/`didUpdateWidget` whenever a badge became newly earned,
  /// which meant the popup ambushed you on any screen that rebuilt Profile —
  /// and stacked several at once when more than one unlocked together. Now
  /// nothing pops on its own: earning a badge lights up its tile with a
  /// "New" marker, and the celebration only plays when the player taps it.
  Future<void> _openCelebration(_Badge badge) async {
    if (!badge.earned) {
      return;
    }
    HapticFeedback.lightImpact();
    final unseen = !stats.celebratedBadges.contains(badge.id);

    await AchievementCelebration.show(
      context,
      title: badge.label,
      subtitle: badge.detail,
      accent: badge.color,
    );

    // Only clear the "New" marker after they've actually watched it, so an
    // unopened badge keeps flagging itself.
    if (unseen && mounted) {
      await context.read<UserStatsController>().markBadgesCelebrated([
        badge.id,
      ]);
    }
  }

  List<_Badge> _badges() {
    final endings = stats.discoveredEndings.length;
    final totalEndings = LifeEndingArchetype.values.length;
    final skins = stats.unlockedSkins.length;
    final totalSkins = budgetBuddySkins.length;
    final lessons = stats.completedLessons.length;

    return <_Badge>[
      _Badge(
        id: 'first_life',
        label: 'First Life',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF85EFAC),
        earned: endings >= 1,
        detail: 'Finish a life',
      ),
      _Badge(
        id: 'storyteller',
        label: 'Storyteller',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFB388FF),
        earned: endings >= 3,
        detail: '3 endings ($endings/$totalEndings)',
      ),
      _Badge(
        id: 'completionist',
        label: 'Completionist',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFFFD45C),
        earned: endings >= totalEndings,
        detail: 'All $totalEndings endings',
      ),
      _Badge(
        id: 'collector',
        label: 'Collector',
        icon: Icons.checkroom_rounded,
        color: const Color(0xFFFF8FB1),
        earned: skins >= 5,
        detail: '5 skins ($skins/$totalSkins)',
      ),
      _Badge(
        id: 'wardrobe',
        label: 'Wardrobe',
        icon: Icons.diamond_rounded,
        color: const Color(0xFF5EE7D6),
        earned: skins >= totalSkins,
        detail: 'Every skin',
      ),
      _Badge(
        id: 'scholar',
        label: 'Scholar',
        icon: Icons.school_rounded,
        color: const Color(0xFF58C7FF),
        earned: lessons >= 5,
        detail: '5 lessons ($lessons)',
      ),
      _Badge(
        id: 'graduate',
        label: 'Graduate',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFE1BB72),
        earned: lessons >= 20,
        detail: '20 lessons',
      ),
      _Badge(
        id: 'veteran',
        label: 'Veteran',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF8A5B),
        earned: stats.level >= 10,
        detail: 'Reach level 10',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final badges = _badges();
    final earned = badges.where((b) => b.earned).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Opaque. A 72%-transparent card over a tiled town map is a card
        // with a map in it — see [_ProfileBackdrop] for why the
        // background was turned down at the same time.
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: AppTheme.puffyShadow(AppTheme.greenPrimary, restAlpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IdleHoverIcon(
                idleAmplitude: 0,
                continuousSpin: earned == badges.length,
                pulseAmplitude: earned == badges.length ? 0.0 : 0.09,
                period: const Duration(seconds: 6),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xFFFFD45C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Badges',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$earned / ${badges.length}',
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFFFFD45C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Tightened per direct feedback that the badge grid was too
              // gappy: a smaller target width fits more per row, and the
              // spacing/height came down with it so the set reads as one
              // trophy case rather than scattered tiles.
              final columns = (constraints.maxWidth / 72).floor().clamp(3, 8);
              final compact = constraints.maxWidth < 380;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: badges.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: compact ? 5 : 6,
                  mainAxisSpacing: compact ? 5 : 6,
                  mainAxisExtent: compact ? 78 : 82,
                ),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return _BadgeTile(
                    badge: badge,
                    isNew:
                        badge.earned &&
                        !stats.celebratedBadges.contains(badge.id),
                    onTap: () => _openCelebration(badge),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.isNew,
    required this.onTap,
  });

  final _Badge badge;

  /// Earned but the celebration hasn't been watched yet — shows a dot so
  /// there's a reason to tap.
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = badge.earned
        ? badge.color
        : Colors.white.withValues(alpha: 0.26);

    return Semantics(
      button: badge.earned,
      label: badge.earned
          ? '${badge.label} earned. ${badge.detail}'
          : '${badge.label} locked. ${badge.detail}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: badge.earned ? onTap : null,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              decoration: BoxDecoration(
                color: badge.earned
                    ? badge.color.withValues(alpha: isNew ? 0.20 : 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: badge.earned
                      ? badge.color.withValues(alpha: isNew ? 0.75 : 0.45)
                      : Colors.white.withValues(alpha: 0.07),
                  width: isNew ? 1.6 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badge.icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 13,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badge.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: badge.earned
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 11,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badge.detail,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: badge.earned ? 0.55 : 0.3,
                          ),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: badge.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: badge.color.withValues(alpha: 0.8),
                        blurRadius: 6,
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

class _ProfileInsightCard extends StatelessWidget {
  const _ProfileInsightCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: AppTheme.puffyShadow(AppTheme.greenPrimary, restAlpha: 0.1),
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

          // Just the metrics. A "Badge Showcase — reserved for earned
          // finance badges" placeholder used to sit under here, directly
          // above the real `_BadgeShowcase`: two cards with the same name
          // and the same trophy glyph, one of which never did anything.
          return metricRow;
        },
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
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
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

/// Hides most of an email while leaving it recognisable to its owner.
///
/// `noobability21@gmail.com` becomes `no••••••••21@gmail.com` — enough for the
/// account holder to confirm it is theirs, not enough for a stranger reading
/// over a shoulder or a screenshot shared in a group chat.
///
/// Short local parts are masked entirely rather than partially: with three
/// characters there is nothing left to hide once you keep two.
String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return 'Signed in';
  final local = email.substring(0, at);
  final domain = email.substring(at);
  if (local.length <= 4) return '${'•' * local.length}$domain';
  final head = local.substring(0, 2);
  final tail = local.substring(local.length - 2);
  return '$head${'•' * (local.length - 4)}$tail$domain';
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
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: AppTheme.puffyShadow(AppTheme.greenPrimary, restAlpha: 0.1),
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
        ),
        // `ListTile.trailing` is *not* width-constrained, so a long trailing
        // widget takes whatever it wants and leaves the title/subtitle column
        // with the remainder. "Level 86 Finance Wizard" squeezed the Account
        // row's subtitle down to roughly one character wide, which is why the
        // email rendered as a vertical stack of single letters.
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: trailing,
        ),
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
        color: AppTheme.panelStrong,
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
    // Boosted rather than dimmed — see [VividBackdrop]. The cards on top
    // are translucent now, so the tile art reads through them instead of
    // the screen being one flat dark slab.
    // Texture, not a picture.
    //
    // This was tuned *up* — saturation 1.4 behind a 0.42 scrim — on the
    // reasoning that translucent cards should let the tile art read through.
    // On a wide window that is exactly what happened, and the result was a
    // town map running through every settings row: grass, fences and trees
    // sliding behind "Notifications" and "Sound" while the labels fought the
    // pattern for legibility. A background on a settings page has one job,
    // which is to not be the thing you are looking at.
    return const VividBackdrop(
      image: AppAssets.profileTileBackground,
      repeat: ImageRepeat.repeat,
      saturation: 0.55,
      brightness: -0.06,
      scrimOpacity: 0.86,
      vignetteOpacity: 0.55,
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

/// Lifetime + month-over-month money-habit totals, plus the trailing-12-week
/// activity heatmap. Reads entirely off [MoneyHabitController], which is
/// itself derived from [UserStatsController]'s stats, so this rebuilds
/// automatically whenever a habit is logged anywhere in the app.
class _MoneyHabitsProfileCard extends StatelessWidget {
  const _MoneyHabitsProfileCard();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final comparison = habits.monthComparison;
    final delta = comparison.lastMonth == null
        ? null
        : comparison.thisMonth.moneySavedUsd -
              comparison.lastMonth!.moneySavedUsd;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: AppTheme.puffyShadow(AppTheme.greenPrimary, restAlpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.savings_rounded,
                color: Color(0xFF85EFAC),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Money Habits',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (delta != null)
                Text(
                  delta >= 0
                      ? '\$${delta.toStringAsFixed(0)} more saved than last month'
                      : '\$${delta.abs().toStringAsFixed(0)} less saved than last month',
                  style: TextStyle(
                    color: delta >= 0
                        ? const Color(0xFF85EFAC)
                        : const Color(0xFFFF8474),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MoneyStatColumn(
                  label: 'Money saved',
                  value:
                      '\$${habits.lifetimeTotals.moneySavedUsd.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _MoneyStatColumn(
                  label: 'Smart choices',
                  value: habits.lifetimeTotals.choicesKept.toStringAsFixed(0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last 12 weeks',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          HabitActivityHeatmap(activityCalendar: habits.activityCalendar),
        ],
      ),
    );
  }
}

class _MoneyStatColumn extends StatelessWidget {
  const _MoneyStatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Friend code display + "add a friend" field + friends list. A friendship
/// is a directed edge (see `SupabaseService.addFriendByCode`), so it reads
/// as mutual once both sides have added each other's code — the empty
/// state explains this rather than promising one-tap mutual adding.
class _FriendsCard extends StatefulWidget {
  const _FriendsCard();

  @override
  State<_FriendsCard> createState() => _FriendsCardState();
}

class _FriendsCardState extends State<_FriendsCard> {
  final _codeController = TextEditingController();
  bool _submitting = false;

  /// The list, held in a field rather than created inline.
  ///
  /// A `FutureBuilder` given `fetch...()` directly re-fetches on every
  /// rebuild — and this card rebuilds on every keystroke in the code field,
  /// so the list would flicker and hammer the server while someone typed.
  Future<List<LeaderboardEntry>>? _friends;
  String? _loadedFor;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _ensureLoaded(String currentUserId) {
    if (currentUserId.isEmpty || _loadedFor == currentUserId) return;
    _loadedFor = currentUserId;
    _friends = SupabaseService.instance.fetchFriendsLeaderboard(
      currentUserId: currentUserId,
    );
  }

  void _reload(String currentUserId) {
    setState(() {
      _friends = SupabaseService.instance.fetchFriendsLeaderboard(
        currentUserId: currentUserId,
      );
    });
  }

  Future<void> _addFriend(String currentUserId) async {
    if (_submitting || _codeController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final result = await SupabaseService.instance.addFriendByCode(
      currentUserId: currentUserId,
      code: _codeController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _codeController.clear();
    GameToast.show(context, message: result);
    // Reload whatever the answer was: a successful add has to appear without
    // the player hunting for a refresh, and a failed one should not leave a
    // stale list looking like it worked.
    _reload(currentUserId);
  }

  Future<void> _removeFriend(String currentUserId, LeaderboardEntry friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panelStrong,
        title: Text(
          'Remove ${friend.username}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'They will drop off your friends leaderboard. You can add them '
          'again with their code.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8474),
              foregroundColor: const Color(0xFF2A0D08),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await SupabaseService.instance.removeFriend(
      currentUserId: currentUserId,
      friendId: friend.id,
    );
    if (!mounted) return;
    GameToast.show(
      context,
      message: ok ? 'Removed ${friend.username}.' : 'Could not remove them.',
    );
    _reload(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserStatsController>().stats.id;
    final friendCode = SupabaseService.friendCodeFor(currentUserId);
    _ensureLoaded(currentUserId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: AppTheme.puffyShadow(AppTheme.greenPrimary, restAlpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_rounded,
                color: Color(0xFF85EFAC),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Friends',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Your code: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: friendCode));
                  GameToast.show(context, message: 'Copied $friendCode');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    friendCode,
                    style: GoogleFonts.pixelifySans(
                      color: Color(0xFF85EFAC),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, color: Colors.white38, size: 14),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter a friend code',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addFriend(currentUserId),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4BD2A3),
                  foregroundColor: const Color(0xFF062017),
                ),
                onPressed: _submitting ? null : () => _addFriend(currentUserId),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF062017),
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FriendsList(
            future: _friends,
            onRemove: (friend) => _removeFriend(currentUserId, friend),
          ),
        ],
      ),
    );
  }
}

/// The friends themselves.
///
/// The card used to be a code plus a text field and nothing else — you could
/// add a friend and never see one, which made the feature impossible to tell
/// apart from a broken one. The empty state explains the two-sided part
/// rather than leaving a blank space to interpret.
class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.future, required this.onRemove});

  final Future<List<LeaderboardEntry>>? future;
  final ValueChanged<LeaderboardEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<LeaderboardEntry>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final friends = snapshot.data ?? const <LeaderboardEntry>[];
        if (friends.isEmpty) {
          return Text(
            'No friends yet. Share your code, or enter someone else\'s — '
            'either of you adding the other is enough for you both to show '
            'up here.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        return Column(
          children: [
            for (final friend in friends)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      backgroundImage: friend.profileImageUrl.isEmpty
                          ? null
                          : NetworkImage(friend.profileImageUrl),
                      child: friend.profileImageUrl.isEmpty
                          ? Text(
                              friend.username.isEmpty
                                  ? '?'
                                  : friend.username.characters.first
                                        .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${friend.literacyPoints} literacy · '
                            '${friend.gold} gold',
                            style: GoogleFonts.quicksand(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove friend',
                      onPressed: () => onRemove(friend),
                      icon: Icon(
                        Icons.person_remove_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
