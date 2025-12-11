import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/data/datasources/user_remote_data_source.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/user_profile_update.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.session,
    required this.language,
    required this.profile,
  });

  final AuthSession session;
  final AppLanguage language;
  final UserProfile? profile;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  static const Color _accent = Color(0xFF3A6FD8);
  static const Color _softAccent = Color(0xFF6FAEF7);

  final _formKey = GlobalKey<FormState>();
  late final UserRepository _repository;

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _portfolioCtrl;

  bool _skillsCompleted = false;
  bool _submitting = false;

  UserProfile? _profile;
  bool _loadingProfile = false;
  bool _profileError = false;

  bool _loginExpanded = false;
  bool _userExpanded = false;
  bool _skillsExpanded = false;
  bool _hasUpdated = false;
  String _selectedGender = 'other';

  @override
  void initState() {
    super.initState();
    _repository = UserRepository(
      remoteDataSource: UserRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _displayNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _genderCtrl = TextEditingController();
    _skillsCtrl = TextEditingController();
    _portfolioCtrl = TextEditingController();

    _applyProfile(widget.profile);
    if (_profile == null) {
      _fetchProfile();
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    _skillsCtrl.dispose();
    _portfolioCtrl.dispose();
    super.dispose();
  }

  void _applyProfile(UserProfile? profile) {
    _profile = profile;
    if (profile == null) return;
    _displayNameCtrl.text = profile.displayName;
    _phoneCtrl.text = profile.phone ?? '';
    _genderCtrl.text = profile.gender ?? '';
    _skillsCtrl.text = profile.skills ?? '';
    _portfolioCtrl.text = profile.portfolioUrl ?? '';
    _skillsCompleted = profile.skillsCompleted ?? false;
    _selectedGender = (profile.gender?.isNotEmpty ?? false)
        ? profile.gender!.toLowerCase()
        : 'other';
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = false;
    });
    try {
      final profile = await _repository.fetchProfile(
        widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _applyProfile(profile);
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = true;
      });
    }
  }

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = UserProfileUpdate(
        displayName: _displayNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gender: _genderCtrl.text.trim(),
        skills: _skillsCtrl.text.trim(),
        skillsCompleted: _skillsCompleted,
        portfolioUrl: _portfolioCtrl.text.trim(),
      );
      await _repository.updateProfile(
        accessToken: widget.session.accessToken,
        update: payload,
      );
      if (!mounted) return;
      setState(() => _hasUpdated = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Cập nhật thông tin thành công', 'Profile updated'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Có lỗi xảy ra: $error', 'Error: $error'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_hasUpdated);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_hasUpdated),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _t('Cấu hình tài khoản', 'Account Settings'),
            style: const TextStyle(
              color: Color(0xFF17304E),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: _loadingProfile
              ? const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _profileError
              ? _ErrorState(onRetry: _fetchProfile, t: _t)
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _sectionCard(
                          title: _t('Thông tin đăng nhập', 'Login information'),
                          expanded: _loginExpanded,
                          onExpandedChanged: (value) =>
                              setState(() => _loginExpanded = value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoField(
                                label: 'Email',
                                value: profile?.email ?? '—',
                              ),
                              const SizedBox(height: 12),
                              _infoField(
                                label: _t('Mã sinh viên', 'Student code'),
                                value: profile?.studentCode ?? '—',
                              ),
                              const SizedBox(height: 12),
                              _infoField(
                                label: _t('Ngành học', 'Major'),
                                value: profile?.majorName ?? '—',
                              ),
                            ],
                          ),
                        ),
                        _sectionCard(
                          title: _t('Thông tin người dùng', 'User details'),
                          expanded: _userExpanded,
                          onExpandedChanged: (value) =>
                              setState(() => _userExpanded = value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _flatField(
                                controller: _displayNameCtrl,
                                label: _t('Tên người dùng', 'Display name'),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? _t('Không được bỏ trống', 'Required')
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _flatField(
                                controller: _phoneCtrl,
                                label: _t('Số điện thoại', 'Phone'),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _genderSelector(),
                              const SizedBox(height: 12),
                              const SizedBox(height: 12),
                              _flatField(
                                controller: _portfolioCtrl,
                                label: 'Portfolio URL',
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _softAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _submitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(_t('Cập nhật', 'Update')),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _sectionCard(
                          title: _t('Kỹ năng', 'Skills'),
                          expanded: _skillsExpanded,
                          onExpandedChanged: (value) =>
                              setState(() => _skillsExpanded = value),
                          child: Column(
                            children: [
                              _blueField(
                                controller: _skillsCtrl,
                                label:'',
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
    );
  }

  Widget _sectionCard({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onExpandedChanged,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpandedChanged,
          title: Text(
            title,
            style: const TextStyle(
              color: _softAccent,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: _softAccent,
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _flatField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 7, 7, 7),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1E2FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC1D8FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderSelector() {
    final options = [
      ('male', _t('Nam', 'Male')),
      ('female', _t('Nữ', 'Female')),
      ('other', _t('Khác', 'Other')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Giới tính', 'Gender'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 7, 7, 7),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.$1,
                  child: Text(
                    option.$2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 9, 9, 10),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedGender = value;
              _genderCtrl.text = value;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1E2FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFC1D8FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _softAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blueField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.trim().isEmpty)
          ? _t('Không được bỏ trống', 'Required')
          : null,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF3A5A8F),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x4C3A6FD8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _infoField({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF1E2F4F),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 9, 9, 10),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD1E2FF)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.t});

  final VoidCallback onRetry;
  final String Function(String, String) t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('Không thể tải thông tin người dùng', 'Unable to load profile'),
          style: const TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(t('Thử lại', 'Retry'))),
      ],
    );
  }
}
