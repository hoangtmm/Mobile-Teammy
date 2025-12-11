import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/forum_repository.dart';

/// Hiển thị modal tạo Personal Profile (bài tìm nhóm)
Future<String?> showCreatePersonalPostModal({
  required BuildContext context,
  required AuthSession session,
  required AppLanguage language,
  required ForumRepository repository,
  required UserProfile userProfile,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: _CreatePersonalPostForm(
          session: session,
          language: language,
          repository: repository,
          userProfile: userProfile,
        ),
      ),
    ),
  );
}

/// Widget form tạo Personal Profile (dùng cho modal)
class _CreatePersonalPostForm extends StatefulWidget {
  const _CreatePersonalPostForm({
    required this.session,
    required this.language,
    required this.repository,
    required this.userProfile,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumRepository repository;
  final UserProfile userProfile;

  @override
  State<_CreatePersonalPostForm> createState() =>
      _CreatePersonalPostFormState();
}

class _CreatePersonalPostFormState extends State<_CreatePersonalPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _submitting = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Parse skills từ user profile (format: "css, html, vite, redux, react")
  List<String> _getUserSkills() {
    final skillsStr = widget.userProfile.skills;
    if (skillsStr == null || skillsStr.isEmpty) return [];

    return skillsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'null')
        .toList();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await widget.repository.createPersonalPost(
        widget.session.accessToken,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _getUserSkills(),
      );

      if (!mounted) return;
      Navigator.pop(context, 'success');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, 'error:$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userSkills = _getUserSkills();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _t('Create Personal Profile', 'Create Personal Profile'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Full Name (readonly)
                  Text(
                    _t('Full Name', 'Full Name'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: widget.userProfile.displayName,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: '* '),
                        TextSpan(text: _t('Title', 'Title')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: _t(
                        'E.g.: Looking for FE team member',
                        'E.g.: Looking for FE team member',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _t('Title is required', 'Title is required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: '* '),
                        TextSpan(text: _t('Description', 'Description')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: _t(
                        'Short description about your need/experience',
                        'Short description about your need/experience',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _t(
                          'Description is required',
                          'Description is required',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Skills (readonly from user profile)
                  Text(
                    _t('Skills', 'Skills'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: userSkills.join(', '),
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(_t('Cancel', 'Cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_t('Publish Profile', 'Publish Profile')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
