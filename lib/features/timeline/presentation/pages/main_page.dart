import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/datasources/user_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../forum/presentation/pages/forum_page.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';
import '../../../group/presentation/pages/group_page.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import 'account_settings_page.dart';
class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.session,
    required this.initialLanguage,
  });

  final AuthSession session;
  final AppLanguage initialLanguage;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late final UserRepository _userRepository;
  late final AuthRepository _authRepository;
  UserProfile? _profile;
  bool _profileLoading = true;
  bool _profileFailed = false;
  late AppLanguage _language;
  double? _dragStartX;
  bool _isUserSheetOpen = false;

  final _tabs = const [
    _BottomTab(
      icon: Icons.view_kanban_outlined,
      labelVi: 'Nhóm',
      labelEn: 'Team',
    ),
    _BottomTab(
      icon: Icons.check_box_outlined,
      labelVi: 'Bảng Kanban',
      labelEn: 'Kanban Board',
    ),
    _BottomTab(
      icon: Icons.forum_outlined,
      labelVi: 'Diễn đàn',
      labelEn: 'Forum',
    ),
    _BottomTab(
      icon: Icons.chat_bubble_outline_rounded,
      labelVi: 'WorkChat',
      labelEn: 'WorkChat',
    ),
  ];

  late final List<_SheetItemData> _sheetItems;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _userRepository = UserRepository(
      remoteDataSource: UserRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _sheetItems = [
      _SheetItemData(
        icon: Icons.manage_accounts_outlined,
        labelVi: 'Cấu hình tài khoản',
        labelEn: 'Account Settings',
        onTap: _openAccountSettings,
      ),
    ];
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userRepository.fetchProfile(
        widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileLoading = false;
        _profileFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileFailed = true;
        _profileLoading = false;
      });
    }
  }

  void _openUserSheet() {
    if (_profileLoading || _isUserSheetOpen) return;
    _isUserSheetOpen = true;
    showGeneralDialog(
      context: context,
      barrierLabel: 'userSheet',
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: _UserSheet(
              profile: _profile,
              language: _language,
              onLanguageChanged: (lang) => setState(() => _language = lang),
              onLogout: _handleLogout,
              items: _sheetItems,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final animationTween =
            Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: animationTween, child: child);
      },
    ).whenComplete(() => _isUserSheetOpen = false);
  }

  Future<void> _handleLogout() async {
    Navigator.of(context).pop();
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (route) => false,
    );
  }

  Future<void> _openAccountSettings() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountSettingsPage(
          session: widget.session,
          language: _language,
          profile: _profile,
        ),
      ),
    );
    if (updated == true) {
      _loadProfile();
    }
  }

  String _translate(String vi, String en) =>
      _language == AppLanguage.vi ? vi : en;

  String _getTabTitle() {
    switch (_selectedIndex) {
      case 1:
        return _translate('Bảng Kanban', 'Kanban Board');
      case 2:
        return _translate('Forum', 'Forum');
      case 3:
        return _translate('WorkChat', 'WorkChat');
      default:
        return _translate('Nhóm', 'Group');
    }
  }

  Widget _buildTabBody() {
    switch (_selectedIndex) {
      case 3:
        return ChatPage(
          session: widget.session,
          language: _language,
          onClose: () => setState(() => _selectedIndex = 0),
        );
      case 1:
        return TasksPage(language: _language, session: widget.session);
      case 2:
        return ForumPage(session: widget.session, language: _language);
      default:
        return GroupPage(session: widget.session, language: _language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) =>
            _dragStartX = details.globalPosition.dx,
        onHorizontalDragUpdate: (details) {
          if (_dragStartX != null &&
              _dragStartX! < 32 &&
              details.globalPosition.dx - _dragStartX! > 60) {
            _dragStartX = null;
            _openUserSheet();
          }
        },
        onHorizontalDragEnd: (_) => _dragStartX = null,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          body: Column(
            children: [
              if (_selectedIndex != 3) ...[
                _AppBar(
                  profile: _profile,
                  isLoading: _profileLoading,
                  onAvatarTap: _openUserSheet,
                  title: _getTabTitle(),
                ),
                if (_profileFailed)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _translate(
                        'Không có thông tin người dùng',
                        'Unable to load profile',
                      ),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
              Expanded(child: _buildTabBody()),
            ],
          ),
          bottomNavigationBar: _selectedIndex == 3
              ? null
              : SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3E5E9))),
              ),
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final isActive = index == _selectedIndex;
                  final color = isActive
                      ? const Color.fromARGB(255, 65, 157, 173)
                      : const Color(0xFF9CA3AF);
                  final label = _language == AppLanguage.vi
                      ? tab.labelVi
                      : tab.labelEn;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 25, color: color),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.profile,
    required this.isLoading,
    required this.onAvatarTap,
    required this.title,
  });

  final UserProfile? profile;
  final bool isLoading;
  final VoidCallback onAvatarTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final initials = (profile?.displayName.isNotEmpty == true)
        ? profile!.displayName[0]
        : 'T';
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: isLoading ? null : onAvatarTap,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE4E7EC),
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF39476A),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2B57),
              ),
            ),
            const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF39476A),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSheet extends StatefulWidget {
  const _UserSheet({
    required this.profile,
    required this.language,
    required this.onLanguageChanged,
    required this.onLogout,
    required this.items,
  });

  final UserProfile? profile;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onLogout;
  final List<_SheetItemData> items;

  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  late AppLanguage _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
  }

  String _translate(String vi, String en) =>
      _currentLanguage == AppLanguage.vi ? vi : en;

  void _onSelectLanguage(AppLanguage lang) {
    setState(() => _currentLanguage = lang);
    widget.onLanguageChanged(lang);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final displayName = widget.profile?.displayName;
    final email = widget.profile?.email ?? '';
    final initials = (displayName?.isNotEmpty ?? false)
        ? displayName!.substring(0, 1).toUpperCase()
        : 'T';

    final sheetWidth = size.width >= 480 ? 360.0 : size.width * 0.85;

    return SizedBox(
      height: size.height,
      width: sheetWidth,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Material(
          color: Colors.white,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFE4E7EC),
                          backgroundImage: widget.profile?.avatarUrl != null
                              ? NetworkImage(widget.profile!.avatarUrl!)
                              : null,
                          child: widget.profile?.avatarUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF39476A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const Spacer(),
                        Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: const PopupMenuThemeData(
                              color: Color(0xFFE8EEFF),
                              textStyle: TextStyle(
                                color: Color(0xFF3A6FD8),
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          child: PopupMenuButton<AppLanguage>(
                            onSelected: _onSelectLanguage,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => AppLanguage.values
                                .map(
                                  (lang) => PopupMenuItem<AppLanguage>(
                                    value: lang,
                                    child: Row(
                                      children: [
                                        Text(lang.displayName),
                                        const SizedBox(width: 8),
                                        Text(lang.flag),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _currentLanguage.shortLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B2B57),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(_currentLanguage.flag),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName?.isNotEmpty == true
                          ? displayName!
                          : 'Teammy User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C293F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7C8696),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...widget.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        minLeadingWidth: 32,
                        leading: Icon(
                          item.icon,
                          color: const Color(0xFF4B5675),
                        ),
                        title: Text(
                          _translate(item.labelVi, item.labelEn),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1D2A4A),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFD0D5E1),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Future.microtask(() => item.onTap?.call());
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minLeadingWidth: 32,
                      leading: const Icon(
                        Icons.logout,
                        color: Color(0xFF4B5675),
                      ),
                      title: Text(
                        _translate('Đăng xuất', 'Logout'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1D2A4A),
                        ),
                      ),
                      onTap: _handleLogoutTap,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: const [
                          Icon(Icons.help_outline, color: Color(0xFF4B5675)),
                          SizedBox(height: 8),
                          Text(
                            'Version 1.0.10 (69)',
                            style: TextStyle(color: Color(0xFF8A94A5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogoutTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color.fromARGB(255, 214, 231, 243),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _translate('Đăng xuất', 'Logout'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C293F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _translate(
                    'Bạn có chắc chắn muốn đăng xuất?',
                    'Are you sure you want to logout?',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 12, 12, 12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A8DBB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          _translate('Có', 'Yes'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          _translate('Không', 'No'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C293F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed == true) {
      widget.onLogout();
    }
  }
}

class _SheetItemData {
  const _SheetItemData({
    required this.icon,
    required this.labelVi,
    required this.labelEn,
    this.onTap,
  });

  final IconData icon;
  final String labelVi;
  final String labelEn;
  final VoidCallback? onTap;
}

class _BottomTab {
  const _BottomTab({
    required this.icon,
    required this.labelVi,
    required this.labelEn,
  });

  final IconData icon;
  final String labelVi;
  final String labelEn;
}
