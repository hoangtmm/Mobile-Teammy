import '../../domain/entities/skill.dart';

class SkillModel extends Skill {
  const SkillModel({
    required super.skillId,
    required super.skillName,
    required super.category,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'skillName': skillName,
      'category': category,
    };
  }
}
