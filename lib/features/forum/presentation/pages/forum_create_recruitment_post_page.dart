import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/forum_membership.dart';
import '../../domain/repositories/forum_repository.dart';

/// Hiển thị modal tạo bài tuyển thành viên
Future<String?> showCreateRecruitmentPostModal({
  required BuildContext context,
  required AuthSession session,
  required AppLanguage language,
  required ForumRepository repository,
  ForumMembership? membership,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: _CreateRecruitmentPostForm(
          session: session,
          language: language,
          repository: repository,
          membership: membership,
        ),
      ),
    ),
  );
}

class _SkillOption {
  final String token;
  final String role;
  final List<String> aliases;

  const _SkillOption({
    required this.token,
    required this.role,
    this.aliases = const [],
  });

  factory _SkillOption.fromJson(Map<String, dynamic> json) {
    return _SkillOption(
      token: json['token'] as String,
      role: json['role'] as String,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
    );
  }

  String get displayName {
    if (aliases.isNotEmpty) return aliases.first;
    return token;
  }
}

/// Widget form tạo bài tuyển (dùng cho modal)
class _CreateRecruitmentPostForm extends StatefulWidget {
  const _CreateRecruitmentPostForm({
    required this.session,
    required this.language,
    required this.repository,
    this.membership,
  });

  final AuthSession session;
  final AppLanguage language;
  final ForumRepository repository;
  final ForumMembership? membership;

  @override
  State<_CreateRecruitmentPostForm> createState() =>
      _CreateRecruitmentPostFormState();
}

class _CreateRecruitmentPostFormState
    extends State<_CreateRecruitmentPostForm> {
  final _formKey = GlobalKey<FormState>();

  final _groupIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();

  DateTime? _expiresAt;
  bool _submitting = false;

  // ==== SKILL STATE ====
  final List<String> _selectedSkills = [];
  String _skillRole = 'all'; // all, frontend, backend, mobile, devops, qa

  // danh sách skill lấy từ BE
  List<_SkillOption> _allSkillOptions = [];
  bool _loadingSkills = false;
  String? _skillsError;

  // ==== GROUP NAME STATE ====
  String? _groupName;
  bool _loadingGroupName = false;

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  // filter theo tab (All / Frontend / Backend / ...)
  List<_SkillOption> get _filteredSkillOptions {
    if (_skillRole == 'all') return _allSkillOptions;
    return _allSkillOptions.where((s) => s.role == _skillRole).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.membership?.groupId != null) {
      _groupIdController.text = widget.membership!.groupId!;
      _loadGroupName();
    }
    _loadSkills();
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupName() async {
    final groupId = widget.membership?.groupId;
    if (groupId == null) return;

    setState(() {
      _loadingGroupName = true;
    });

    try {
      final result = await widget.repository.fetchGroupDetails(
        widget.session.accessToken,
        groupId,
      );

      if (!mounted) return;
      setState(() {
        _groupName = result?['name'] as String?;
        _loadingGroupName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGroupName = false;
      });
    }
  }

  Future<void> _loadSkills() async {
    setState(() {
      _loadingSkills = true;
      _skillsError = null;
    });

    try {
      // TODO: Get major from user profile when available
      const major = 'Software Engineering';

      final result = await widget.repository.fetchSkills(
        widget.session.accessToken,
        major: major,
      );

      final List<_SkillOption> options = [];

      for (final s in result) {
        options.add(_SkillOption.fromJson(s));
      }

      if (!mounted) return;
      setState(() {
        _allSkillOptions = options;
        _loadingSkills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSkills = false;
        _skillsError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Không thể tải danh sách kỹ năng: $e',
              'Failed to load skills: $e',
            ),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _toggleSkill(String name) {
    setState(() {
      if (_selectedSkills.contains(name)) {
        _selectedSkills.remove(name);
      } else {
        _selectedSkills.add(name);
      }
    });
  }

  Widget _buildSkillCategoryChips() {
    final items = <(String, String)>[
      ('all', _t('Tất cả', 'All')),
      ('frontend', 'Frontend'),
      ('backend', 'Backend'),
      ('mobile', 'Mobile'),
      ('devops', 'DevOps'),
      ('qa', 'QA'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final role = item.$1;
          final label = item.$2;
          final selected = _skillRole == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF374151),
                ),
              ),
              selected: selected,
              selectedColor: const Color(0xFF111827),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              onSelected: (_) {
                setState(() => _skillRole = role);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _t('Kỹ năng yêu cầu', 'Required Skills'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),

        // Selected skills box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(
                  'Kỹ năng đã chọn (${_selectedSkills.length})',
                  'Selected skills (${_selectedSkills.length})',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedSkills.isEmpty)
                Text(
                  _t(
                    'Chưa có kỹ năng nào. Hãy chọn ở phía dưới.',
                    'No skills selected. Tap skills below to add.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills
                      .map(
                        (s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFE5EDFF),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _toggleSkill(s),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Filter tabs
        _buildSkillCategoryChips(),
        const SizedBox(height: 8),

        // Available skills list
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: _loadingSkills
              ? const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _allSkillOptions.isEmpty
              ? Text(
                  _t(
                    'Không có kỹ năng nào cho ngành này.',
                    'No skills available for this major.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredSkillOptions.map((opt) {
                    final selected = _selectedSkills.contains(opt.token);
                    return FilterChip(
                      label: Text(
                        opt.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF4F46E5),
                      backgroundColor: const Color(0xFFF3F4F6),
                      onSelected: (_) => _toggleSkill(opt.token),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  List<String> _parseSkills() {
    return List<String>.from(_selectedSkills);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Vui lòng chọn ít nhất 1 kỹ năng',
              'Please select at least 1 required skill',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.repository.createRecruitmentPost(
        widget.session.accessToken,
        groupId: _groupIdController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        positionNeeded: _positionController.text.trim(),
        expiresAt: _expiresAt,
        skills: _parseSkills(),
      );

      if (!mounted) return;
      Navigator.of(context).pop('success');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Không thể tạo bài tuyển: $e', 'Failed to create post: $e'),
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
                  _t('Tạo bài tuyển thành viên', 'Create recruitment post'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
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
                  Text(
                    _t(
                      'Đăng bài để tuyển thêm thành viên cho nhóm capstone của bạn.',
                      'Create a post to recruit more members for your capstone group.',
                    ),
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: TextEditingController(
                      text: _loadingGroupName
                          ? _t('Đang tải...', 'Loading...')
                          : (_groupName ?? _groupIdController.text),
                    ),
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: _t('Nhóm của bạn', 'Your Group'),
                      helperText: _t(
                        'Bài tuyển sẽ được đăng cho nhóm này',
                        'Post will be created for this group',
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      suffixIcon: _loadingGroupName
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (_groupIdController.text.trim().isEmpty) {
                        return _t(
                          'Không tìm thấy thông tin nhóm',
                          'Group information not found',
                        );
                      }
                      return null;
                    },
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
                    controller: _positionController,
                    decoration: InputDecoration(
                      labelText: _t(
                        'Vị trí cần tuyển',
                        'Position needed (e.g. Frontend)',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSkillsSection(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _expiresAt == null
                              ? _t(
                                  'Chưa chọn ngày hết hạn',
                                  'No expiration date selected',
                                )
                              : _t(
                                  'Hết hạn: ${_expiresAt!.toLocal().toString().split(' ').first}',
                                  'Expires at: ${_expiresAt!.toLocal().toString().split(' ').first}',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: Text(_t('Chọn ngày', 'Pick date')),
                      ),
                    ],
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
      ],
    );
  }
}
