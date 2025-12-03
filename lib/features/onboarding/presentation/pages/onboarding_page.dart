import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/widgets/teammy_logo.dart';
import '../../../../core/localization/app_language.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.titleVi,
    required this.titleEn,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.colors,
    required this.icon,
  });

  final String titleVi;
  final String titleEn;
  final String descriptionVi;
  final String descriptionEn;
  final List<Color> colors;
  final IconData icon;
}

final _slides = [
  OnboardingSlide(
    titleVi: 'Chào mừng đến Teammy.',
    titleEn: 'Welcome to Teammy.',
    descriptionVi:
        'Nâng tầm hiệu quả làm việc nhóm với phần mềm quản lý công việc và giao tiếp toàn diện.',
    descriptionEn:
        'Level up teamwork efficiency with an all-in-one work management and communication hub.',
    colors: const [Color(0xFF4E6FFB), Color(0xFF8E6DFF)],
    icon: Icons.dashboard_customize_rounded,
  ),
  OnboardingSlide(
    titleVi: 'Quản lý công việc dễ dàng',
    titleEn: 'Manage work with ease',
    descriptionVi:
        'Tạo nhiệm vụ, theo dõi tiến độ, cộng tác hiệu quả. Lập kế hoạch dự án, quản lý thời gian.',
    descriptionEn:
        'Create tasks, track progress, collaborate smoothly. Plan projects and keep timing on track.',
    colors: const [Color(0xFF50C2CB), Color(0xFF4E83FB)],
    icon: Icons.calendar_month,
  ),
  OnboardingSlide(
    titleVi: 'Giao tiếp, cộng tác liền mạch',
    titleEn: 'Communicate seamlessly',
    descriptionVi:
        'Trò chuyện trực tiếp, theo nhóm, @mention và Zoom miễn phí. Khảo sát, biểu quyết, ý kiến nhóm.',
    descriptionEn:
        'Chat instantly, mention teammates, host free video calls, run polls and capture insights.',
    colors: const [Color(0xFF735CFF), Color(0xFFFA709A)],
    icon: Icons.forum_rounded,
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentIndex = 0;
  AppLanguage _language = AppLanguage.vi;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const TeammyLogo(),
            const SizedBox(height: 24),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _slides.length,
                itemBuilder: (_, index) => _SlideView(
                  slide: _slides[index],
                  language: _language,
                ),
              ),
            ),
            _Indicator(currentIndex: _currentIndex, total: _slides.length),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4E6FFB),
                            Color(0xFF4BD2B0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoginPage(initialLanguage: _language),
                            ),
                          );
                        },
                        child: Text(
                          _language == AppLanguage.vi ? 'ĐĂNG NHẬP' : 'LOGIN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _LanguageSwitch(
              activeLanguage: _language,
              onSelect: (lang) => setState(() => _language = lang),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.language});

  final OnboardingSlide slide;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final title = language == AppLanguage.vi ? slide.titleVi : slide.titleEn;
    final description =
        language == AppLanguage.vi ? slide.descriptionVi : slide.descriptionEn;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _Illustration(colors: slide.colors, icon: slide.icon),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2A4A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF7D8699),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.colors, required this.icon});

  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 68,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              6,
              (index) => Container(
                width: 54,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.currentIndex, required this.total});

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 16 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF45B549)
                : const Color(0xFFD7DCE5),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({
    required this.activeLanguage,
    required this.onSelect,
  });

  final AppLanguage activeLanguage;
  final ValueChanged<AppLanguage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LanguageButton(
          text: 'Tiếng Việt',
          isActive: activeLanguage == AppLanguage.vi,
          onTap: () => onSelect(AppLanguage.vi),
        ),
        const SizedBox(width: 20),
        _LanguageButton(
          text: 'Tiếng Anh',
          isActive: activeLanguage == AppLanguage.en,
          onTap: () => onSelect(AppLanguage.en),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  final String text;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xFF45B549) : const Color(0xFF9BA2B1),
        ),
      ),
    );
  }
}
