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
  
  bool _loading = true;
  bool _submitting = false;
  String? _error;

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load skills';
        _loading = false;
      });
    }
  }

  Future<void> _handleCreateGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Vui long nhap ten nhom', 'Please enter group name'))),
      );
      return;
    }

    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Vui long chon it nhat 1 ky nang', 'Please select at least 1 skill'))),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _repository.createGroup(
        widget.accessToken,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        maxMembers: int.tryParse(_maxMembersCtrl.text) ?? 5,
        skills: _selectedSkillIds.toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onGroupCreated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

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
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
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
                    _t('Tao Nhom Moi', 'Create New Group'),
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
              
              // Tên nhóm
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: _t('Ten Nhom *', 'Group Name *'),
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
                  labelText: _t('Mo Ta', 'Description'),
                  hintText: _t('Muc tieu, cong nghe su dung...', 'Goals, tech stack...'),
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
                  labelText: _t('So Thanh Vien Toi Da *', 'Max Members *'),
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
                _t('Ky Nang *', 'Skills *'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C293F),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSkills.map((skill) {
                  final isSelected = _selectedSkillIds.contains(skill.skillId);
                  return FilterChip(
                    label: Text(skill.skillName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkillIds.add(skill.skillId);
                        } else {
                          _selectedSkillIds.remove(skill.skillId);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3A6FD8),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF3A6FD8)
                          : const Color(0xFFD0D5E1),
                    ),
                  );
                }).toList(),
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
                        _t('Huy', 'Cancel'),
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
                              _t('Tao Nhom', 'Create Group'),
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
