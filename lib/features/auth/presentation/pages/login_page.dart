import 'package:flutter/material.dart';

import '../../../timeline/presentation/pages/timeline_page.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.initialLanguage});

  final AppLanguage initialLanguage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _selectedCampus;
  final _campuses = const [
    'Hanoi Campus',
    'Ho Chi Minh Campus',
    'Da Nang Campus',
  ];
  late final AuthRepository _authRepository;
  late AppLanguage _language;
  bool _isLoading = false;
  String? _errorMessage;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSource(
        baseUrl: kApiBaseUrl,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _session = null;
    });
    try {
      final session = await _authRepository.signInWithGoogle();
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate('Chào mừng ${session.displayName}!', 'Welcome ${session.displayName}!'),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TimelinePage(
            session: session,
            initialLanguage: _language,
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Server error (${error.statusCode}). Please try again.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unexpected error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _translate(String vi, String en) =>
      _language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      const SizedBox(height: 32),
                            const _LogoSection(),
                            const SizedBox(height: 24),
                            _LoginCard(
                              campuses: _campuses,
                              selectedCampus: _selectedCampus,
                              onCampusChanged: (value) {
                                setState(() => _selectedCampus = value);
                              },
                              isLoading: _isLoading,
                              onGoogleTap: _handleGoogleSignIn,
                              language: _language,
                              errorMessage: _errorMessage,
                              session: _session,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5ED4FF),
                Color(0xFF5067FF),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'T',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Teammy',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2440),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.campuses,
    required this.selectedCampus,
    required this.onCampusChanged,
    required this.isLoading,
    required this.onGoogleTap,
    required this.language,
    this.errorMessage,
    this.session,
  });

  final List<String> campuses;
  final String? selectedCampus;
  final ValueChanged<String?> onCampusChanged;
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final AppLanguage language;
  final String? errorMessage;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    String tr(String vi, String en) =>
        language == AppLanguage.vi ? vi : en;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Chào mừng trở lại', 'Welcome back'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2845),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Đăng nhập bằng Google để truy cập Teammy',
                'Sign in with your Google account to access Teammy'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF62718D),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('Chọn cơ sở', 'Select campus'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222D54),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCampus,
            items: campuses
                .map(
                  (campus) => DropdownMenuItem<String>(
                    value: campus,
                    child: Text(campus),
                  ),
                )
                .toList(),
            onChanged: onCampusChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFFE0E4F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFF5161F1)),
              ),
            ),
            hint: Text(tr('Chọn cơ sở', 'Select Campus')),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              side: const BorderSide(color: Color(0xFFE0E4F2)),
              backgroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : onGoogleTap,
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E8F7),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4153B7),
                  ),
                ),
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      key: ValueKey('label'),
                      tr('Tiếp tục với Google', 'Continue with Google'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2448),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD93025),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (session != null) ...[
            Text(
              tr('Đã đăng nhập với ${session!.displayName}',
                  'Signed in as ${session!.displayName}'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5161F1),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            tr('Bằng cách tiếp tục, bạn đồng ý với điều khoản sử dụng của Teammy.',
                'By continuing, you agree to Teammy\'s terms of use.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A92B2),
            ),
          ),
        ],
      ),
    );
  }
}
