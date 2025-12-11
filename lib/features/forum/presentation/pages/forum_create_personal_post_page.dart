import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

class ForumCreatePersonalPostPage extends StatefulWidget {
  const ForumCreatePersonalPostPage({
    super.key,
    required this.session,
    required this.language,
    required this.repository,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumRepository repository;

  @override
  State<ForumCreatePersonalPostPage> createState() =>
      _ForumCreatePersonalPostPageState();
}

class _ForumCreatePersonalPostPageState
    extends State<ForumCreatePersonalPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _submitting = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _parseSkills() {
    return _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final post = await widget.repository.createPersonalPost(
        widget.session.accessToken,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _parseSkills(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Đã tạo bài giới thiệu cá nhân', 'Personal post created'),
          ),
        ),
      );
      Navigator.of(context).pop<ForumPost>(post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Không thể tạo bài giới thiệu: $e', 'Failed to create post: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Tạo bài tìm nhóm', 'Create personal post')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  _t(
                    'Giới thiệu bản thân để leader có thể mời bạn vào nhóm.',
                    'Introduce yourself so group leaders can invite you.',
                  ),
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _t('Tiêu đề', 'Title'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _t(
                        'Vui lòng nhập tiêu đề',
                        'Please enter a title',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: _t('Mô tả', 'Description'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _t(
                        'Vui lòng nhập mô tả',
                        'Please enter a description',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'Kỹ năng (phân cách bằng dấu phẩy)',
                      'Skills (comma separated)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_t('Đăng bài', 'Post')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
