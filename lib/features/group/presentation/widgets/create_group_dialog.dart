import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/skill.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({
    super.key,
    required this.language,
    required this.accessToken,
    required this.userMajor,
    this.onGroupCreated,
  });

  final AppLanguage language;
  final String accessToken;
  final String userMajor;
  final VoidCallback? onGroupCreated;

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  late final GroupRepositoryImpl _repository;
  
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxMembersCtrl = TextEditingController(text: '5');
  
  List<Skill> _allSkills = [];
  Set<String> _selectedSkillIds = {};
  String? _selectedCategory; // null = All
  
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _repository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _loadMajorsAndSkills();
  }

  Future<void> _loadMajorsAndSkills() async {
    try {
      // Lấy skills theo major của user
      final skills = await _repository.fetchSkillsByMajor(
        widget.accessToken,
        widget.userMajor,
      );
      
      if (!mounted) return;
      setState(() {
        _allSkills = skills;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleCreateGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        _validationError = _t('Vui lòng nhập tên nhóm', 'Please enter group name');
      });
      return;
    }

    if (_selectedSkillIds.isEmpty) {
      setState(() {
        _validationError = _t('Vui lòng chọn ít nhất 1 kỹ năng', 'Please select at least 1 skill');
      });
      return;
    }

    setState(() {
      _submitting = true;
      _validationError = null;
    });

    try {
      await _repository.createGroup(
        widget.accessToken,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        maxMembers: int.tryParse(_maxMembersCtrl.text) ?? 5,
        skills: _selectedSkillIds.toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onGroupCreated?.call();
    } catch (e) {
      if (!mounted) return;
      
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // Translate error message
      errorMessage = _translateErrorMessage(errorMessage);
      
      setState(() {
        _error = errorMessage;
        _submitting = false;
      });
      
      // Show error dialog to user
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(_t('Lỗi', 'Error')),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('Đóng', 'Close')),
            ),
          ],
        ),
      );
    }
  }

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'frontend':
        return const Color(0xFF3A6FD8); // Blue
      case 'backend':
        return const Color(0xFFF59E0B); // Orange
      case 'devops':
        return const Color(0xFF10B981); // Green
      case 'qa':
        return const Color(0xFFEF4444); // Red
      case 'mobile':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Widget _buildCategoryButton(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _getCategoryColor(category ?? 'all') : Colors.white,
          border: Border.all(
            color: isSelected
                ? _getCategoryColor(category ?? 'all')
                : const Color(0xFFD0D5E1),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  String _translateErrorMessage(String errorMessage) {
    // Map common server error messages to translations
    const errorMap = {
      "Members must be between 4 and 6 in this semester": "Số thành viên phải từ 4 đến 6 trong kỳ học này",
      "Group name already exists": "Tên nhóm đã tồn tại",
      "Invalid skills": "Kỹ năng không hợp lệ",
      "Unauthorized": "Không có quyền truy cập",
    };

    // Check if error message matches any known errors
    for (final entry in errorMap.entries) {
      if (errorMessage.contains(entry.key)) {
        return widget.language == AppLanguage.vi ? entry.value : errorMessage;
      }
    }

    // Return original message if no match found
    return errorMessage;
  }

    @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxMembersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFFAFBFC),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t('Tạo Nhóm Mới', 'Create New Group'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C293F),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(FeatherIcons.x, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Validation error message
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FeatherIcons.alertCircle,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Tên nhóm
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: _t('Tên Nhóm *', 'Group Name *'),
                  hintText: _t('VD: AI Capstone', 'E.g., AI Capstone'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _t('Mô Tả', 'Description'),
                  hintText: _t('Mục tiêu, công nghệ sử dụng...', 'Goals, tech stack...'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Max Members
              TextField(
                controller: _maxMembersCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _t('Số Thành Viên Tối Đa *', 'Max Members *'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Skills
              Text(
                _t('Kỹ Năng *', 'Skills *'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C293F),
                ),
              ),
              const SizedBox(height: 12),

              // Selected Skills
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFFAFBFC),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Đã chọn Kỹ Năng (0)', 'Selected Skills (${_selectedSkillIds.length})'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedSkillIds.isEmpty)
                      Text(
                        _t('Nhấn vào các kỹ năng dưới để thêm vào', 'Click skills below to add them'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allSkills
                            .where((s) => _selectedSkillIds.contains(s.skillId))
                            .map((skill) => Chip(
                              label: Text(skill.skillName),
                              onDeleted: () {
                                setState(() {
                                  _selectedSkillIds.remove(skill.skillId);
                                });
                              },
                              backgroundColor: _getCategoryColor(skill.category).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _getCategoryColor(skill.category),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryButton('All', null),
                    const SizedBox(width: 8),
                    _buildCategoryButton('Frontend', 'frontend'),
                    const SizedBox(width: 8),
                    _buildCategoryButton('Devops', 'devops'),
                    const SizedBox(width: 8),
                    _buildCategoryButton('Backend', 'backend'),
                    const SizedBox(width: 8),
                    _buildCategoryButton('QA', 'qa'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Available Skills
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Kỹ Năng Không Dùng (Nhấn để thêm)', 'Available Skills (Click to add)'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allSkills
                            .where((skill) => !_selectedSkillIds.contains(skill.skillId))
                            .where((skill) {
                              if (_selectedCategory == null) return true;
                              return skill.category.toLowerCase() == _selectedCategory!.toLowerCase();
                            })
                            .toList()
                            .map((skill) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSkillIds.add(skill.skillId);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(skill.category).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getCategoryColor(skill.category).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill.skillName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getCategoryColor(skill.category),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _getCategoryColor(skill.category),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFD0D5E1)),
                      ),
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        _t('Hủy', 'Cancel'),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6FD8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _handleCreateGroup,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _t('Tạo Nhóm', 'Create Group'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
