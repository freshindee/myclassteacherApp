import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/widgets/resolved_firebase_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'class_videos_page.dart';
import 'free_videos_page.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../../injection_container.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import 'today_classes_page.dart';
import 'teachers_page.dart';
import 'past_months_recordings_page.dart';
import 'past_months_notes_page.dart';
import 'free_videos_bloc.dart';
import 'grades_list_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import 'online_exam_selection_page.dart';

// ---------------------------------------------------------------------------
// Tile data model
// ---------------------------------------------------------------------------

class _NavTileSpec {
  const _NavTileSpec({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.builder,
    this.badge = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Widget Function(
    BuildContext, {
    required bool embedInHomeShell,
  }) builder;
  final bool badge;
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _bgColor = Color(0xFFF1F5F9);
  int _selectedPanelIndex = 0;

  static const _schoolDetailKeys = [
    'school_name',
    'institute_name',
    'school_display_name',
    'schoolName',
  ];

  /// Memoize hero-content future per logged-in school id.
  String? _heroContentFutureSchoolId;
  Future<_HeroContent>? _heroContentFuture;

  void _ensureHeroContentFuture(String schoolId, String userName) {
    if (_heroContentFutureSchoolId != schoolId) {
      _heroContentFutureSchoolId = schoolId;
      _heroContentFuture = _loadHeroContent(schoolId, userName);
    }
  }

  /// Session first (filled at login from `schools/{id}`); else one Firestore read, then cache in session.
  static Future<_HeroContent> _loadHeroContent(String schoolId, String userName) async {
    final details = await UserSessionService.getStudentDetails();
    final schoolName = _schoolNameFromStudentDetails(details) ??
        AppConstants.defaultSchoolDisplayName;
    final headingFromSession = _readString(details, 'heading_text');
    final todayFromSession = _readString(details, 'today_message');
    final logoFromSession = _readString(details, 'logo');
    if (headingFromSession != null &&
        todayFromSession != null &&
        logoFromSession != null) {
      return _HeroContent(
        schoolName: schoolName,
        headingText: headingFromSession,
        todayMessage: todayFromSession,
        logoUrl: logoFromSession,
      );
    }

    if (schoolId.isEmpty) {
      return _HeroContent(
        schoolName: schoolName,
        headingText: 'Welcome to $schoolName, $userName!',
        todayMessage: '',
        logoUrl: logoFromSession,
      );
    }

    try {
      final snap =
          await FirebaseFirestore.instance.collection('schools').doc(schoolId).get();
      final map = snap.data();
      final resolvedSchoolName = _readString(map, 'school_name') ?? schoolName;
      final resolvedHeading = _readString(map, 'heading_text') ??
          'Welcome to $resolvedSchoolName, $userName!';
      final resolvedMessage = _readString(map, 'today_message') ?? '';
      final resolvedLogo = _readString(map, 'logo') ??
          _readString(map, 'logo_url') ??
          _readString(map, 'school_logo');
      await UserSessionService.mergeStudentDetails({
        'school_name': resolvedSchoolName,
        'heading_text': resolvedHeading,
        'today_message': resolvedMessage,
        if (resolvedLogo != null) 'logo': resolvedLogo,
      });
      return _HeroContent(
        schoolName: resolvedSchoolName,
        headingText: resolvedHeading,
        todayMessage: resolvedMessage,
        logoUrl: resolvedLogo,
      );
    } catch (e) {
      debugPrint(
        'HomePage: could not load schools/$schoolId hero fields: $e',
      );
      return _HeroContent(
        schoolName: schoolName,
        headingText: headingFromSession ?? 'Welcome to $schoolName, $userName!',
        todayMessage: todayFromSession ?? '',
        logoUrl: logoFromSession,
      );
    }
  }

  static String? _readString(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }

  static String? _schoolNameFromStudentDetails(Map<String, dynamic>? details) {
    if (details == null) return null;
    for (final key in _schoolDetailKeys) {
      final v = details[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Tile specs – same pages as before, now with subtitle text
  // ---------------------------------------------------------------------------

  List<_NavTileSpec> _tileSpecs(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.userId ?? '1';
    final schoolId = authState.user?.teacherId ?? '';

    return [
      _NavTileSpec(
        label: 'නොමිලේ පාඩම්',
        subtitle: 'සෑම දිනකම අලුත් දේ ඉගෙන ගන්න',
        icon: Icons.menu_book_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
        builder: (ctx, {required embedInHomeShell}) => BlocProvider(
          create: (_) => sl<FreeVideosBloc>(),
          child: FreeVideosPage(embedInHomeShell: embedInHomeShell),
        ),
      ),
      _NavTileSpec(
        label: 'මේ මාසේ වීඩියෝ',
        subtitle: 'නවතම වීඩියෝ මාලාවන්',
        icon: Icons.play_circle_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF1D4ED8),
        builder: (ctx, {required embedInHomeShell}) =>
            ClassVideosPage(embedInHomeShell: embedInHomeShell),
      ),
      _NavTileSpec(
        label: 'Zoom පන්ති',
        subtitle: 'සජීවී පන්තියට සම්බන්ධ වන්න',
        icon: Icons.videocam_rounded,
        iconBgColor: const Color(0xFFFFF1F2),
        iconColor: const Color(0xFFE11D48),
        builder: (ctx, {required embedInHomeShell}) =>
            TodayClassesPage(embedInHomeShell: embedInHomeShell),
        badge: true,
      ),
      _NavTileSpec(
        label: 'කාල සටහන',
        subtitle: 'ඔබගේ ඉදිරි වැඩකටයුතු',
        icon: Icons.calendar_month_rounded,
        iconBgColor: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4338CA),
        builder: (ctx, {required embedInHomeShell}) =>
            GradesListPage(embedInHomeShell: embedInHomeShell),
      ),
      _NavTileSpec(
        label: 'පන්ති ගාස්තු ගෙවීම්',
        subtitle: 'ගෙවීම් කටයුතු පහසුවෙන්',
        icon: Icons.account_balance_wallet_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF0D9488),
        builder: (ctx, {required embedInHomeShell}) => BlocProvider(
          create: (_) => sl<PaymentBloc>(),
          child: PaymentPage(
            userId: userId,
            schoolId: schoolId,
            embedInHomeShell: embedInHomeShell,
          ),
        ),
      ),
      _NavTileSpec(
        label: 'අපේ ගුරුවරු',
        subtitle: 'විෂය ප්‍රවීණයන් හමුවන්න',
        icon: Icons.groups_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF1E3A8A),
        builder: (ctx, {required embedInHomeShell}) =>
            TeachersPage(embedInHomeShell: embedInHomeShell),
      ),
      _NavTileSpec(
        label: 'පන්ති නිබන්ධන',
        subtitle: 'අවශ්‍ය සියලුම සටහන්',
        icon: Icons.description_rounded,
        iconBgColor: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        builder: (ctx, {required embedInHomeShell}) =>
            PastMonthsNotesPage(embedInHomeShell: embedInHomeShell),
      ),
      _NavTileSpec(
        label: 'පසුගිය වීඩියෝ',
        subtitle: 'නැවත මතක් කරගැනීමට',
        icon: Icons.history_rounded,
        iconBgColor: const Color(0xFFF8FAFC),
        iconColor: const Color(0xFF64748B),
        builder: (ctx, {required embedInHomeShell}) =>
            PastMonthsRecordingsPage(embedInHomeShell: embedInHomeShell),
      ),
    ];
  }

  // Online-exam spec kept for potential re-use
  // ignore: unused_element
  _NavTileSpec _onlineExamTileSpec() => _NavTileSpec(
        label: 'ප්‍රශ්න පත්‍ර ලියමු',
        subtitle: 'ප්‍රශ්නාවලිය ලිවීමට',
        icon: Icons.quiz_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
        builder: (ctx, {required embedInHomeShell}) =>
            OnlineExamSelectionPage(embedInHomeShell: embedInHomeShell),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          (previous.isLogout != true && current.isLogout == true) ||
          previous.cacheSyncVersion != current.cacheSyncVersion,
      listener: (context, state) {
        if (state.isLogout == true) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        } else {
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Builder(
                  builder: (context) {
                    final specs = _tileSpecs(context);
                    final authState = context.read<AuthBloc>().state;
                    final userName = authState.user?.name ?? 'Student';
                    final userId = authState.user?.userId ?? '';
                    final schoolId = authState.user?.teacherId ?? '';
                    _ensureHeroContentFuture(schoolId, userName);
                    final selectedSpec = specs[_selectedPanelIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder<_HeroContent>(
                          future: _heroContentFuture,
                          builder: (context, snap) {
                            final fallbackSchoolName =
                                AppConstants.defaultSchoolDisplayName;
                            final heroContent = snap.data ??
                                _HeroContent(
                                  schoolName: fallbackSchoolName,
                                  headingText:
                                      'Welcome to $fallbackSchoolName, $userName!',
                                  todayMessage: '',
                                  logoUrl: null,
                                );
                            return _HeroBanner(
                              schoolDisplayName: heroContent.schoolName,
                              userName: userName,
                              headingText: heroContent.headingText,
                              todayMessage: heroContent.todayMessage,
                              logoUrl: heroContent.logoUrl,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _NavGrid(
                          specs: specs,
                          selectedIndex: _selectedPanelIndex,
                          onTileTap: (index) {
                            setState(() => _selectedPanelIndex = index);
                          },
                        ),
                        const SizedBox(height: 24),
                        _BottomSection(
                          userName: userName,
                          userId: userId,
                          selectedSpec: selectedSpec,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero banner widget
// ---------------------------------------------------------------------------

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.schoolDisplayName,
    required this.userName,
    required this.headingText,
    required this.todayMessage,
    required this.logoUrl,
  });

  final String schoolDisplayName;
  final String userName;
  final String headingText;
  final String todayMessage;
  final String? logoUrl;

  static const _heroBlueDark = Color(0xFF1E3A8A);
  static const _heroBlueLight = Color(0xFF1E40AF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_heroBlueDark, _heroBlueLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _heroBlueDark.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to $schoolDisplayName, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (headingText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    headingText,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
                if (todayMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    todayMessage,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // ElevatedButton.icon(
                //   onPressed: onScheduleTap,
                //   icon: const Icon(Icons.event_rounded, size: 18),
                //   label: const Text('අද දවසේ වැඩසටහන'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: _brandGreen,
                //     foregroundColor: Colors.white,
                //     elevation: 0,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 22,
                //       vertical: 13,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     textStyle: const TextStyle(
                //       fontWeight: FontWeight.w600,
                //       fontSize: 14,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Decorative circle – hidden on very small screens
          LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.sizeOf(context).width;
              if (width < 400) return const SizedBox.shrink();
              return Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ClipOval(
                    child: (logoUrl != null && logoUrl!.isNotEmpty)
                        ? FutureBuilder<String>(
                            future: resolveFirebaseImageDownloadUrl(logoUrl!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.prefer,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        size: 56,
                                        color: Color(0xFFBFDBFE),
                                      ),
                                    );
                                  },
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 56,
                              color: Color(0xFFBFDBFE),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroContent {
  const _HeroContent({
    required this.schoolName,
    required this.headingText,
    required this.todayMessage,
    required this.logoUrl,
  });

  final String schoolName;
  final String headingText;
  final String todayMessage;
  final String? logoUrl;
}

// ---------------------------------------------------------------------------
// Navigation tile grid
// ---------------------------------------------------------------------------

class _NavGrid extends StatelessWidget {
  const _NavGrid({
    required this.specs,
    required this.selectedIndex,
    required this.onTileTap,
  });

  final List<_NavTileSpec> specs;
  final int selectedIndex;
  final ValueChanged<int> onTileTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1200
        ? 5
        : width >= 900
            ? 4
            : width >= 700
                ? 3
                : 2;
    final ratio = width >= 1200
        ? 1.45
        : width >= 900
            ? 1.3
            : width >= 700
                ? 1.15
                : 1.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemCount: specs.length,
      itemBuilder: (context, i) => _NavTile(
        spec: specs[i],
        selected: i == selectedIndex,
        onTap: () => onTileTap(i),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavTileSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width >= 1200;
    final iconBoxSize = compact ? 44.0 : 54.0;
    final iconSize = compact ? 22.0 : 26.0;
    final cardPadding = compact ? 12.0 : 16.0;
    final titleSize = compact ? 12.2 : 13.5;
    final subtitleSize = compact ? 10.2 : 11.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(
            0,
            _hovered ? -2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFFECFDF5)
                : (_hovered ? const Color(0xFFF0FDF4) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected
                  ? const Color(0xFF34D399)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _hovered ? 0.08 : 0.03,
                ),
                blurRadius: _hovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: spec.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(spec.icon, color: spec.iconColor, size: iconSize),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    spec.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spec.subtitle,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: const Color(0xFF94A3B8),
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (spec.badge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _PulseDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated red pulse dot (like the live indicator in the HTML)
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom section: profile card + featured free-lessons card
// ---------------------------------------------------------------------------

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.userName,
    required this.userId,
    required this.selectedSpec,
  });

  final String userName;
  final String userId;
  final _NavTileSpec selectedSpec;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: _ProfileCard(userName: userName, userId: userId),
          ),
          const SizedBox(width: 16),
          Expanded(child: _EmbeddedPanelCard(spec: selectedSpec)),
        ],
      );
    }
    return Column(
      children: [
        _ProfileCard(userName: userName, userId: userId),
        const SizedBox(height: 16),
        _EmbeddedPanelCard(spec: selectedSpec),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userName, required this.userId});

  final String userName;
  final String userId;

  static const _heroBlueDark = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _heroBlueDark,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userId.isNotEmpty)
                  Text(
                    'ID: $userId',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedPanelCard extends StatelessWidget {
  const _EmbeddedPanelCard({required this.spec});

  final _NavTileSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              spec.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            height: 620,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: spec.builder(
                  context,
                  embedInHomeShell: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
