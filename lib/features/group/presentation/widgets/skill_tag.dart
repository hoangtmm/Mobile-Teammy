import 'package:flutter/material.dart';

class SkillTag extends StatelessWidget {
  final String skill;

  const SkillTag({
    super.key,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF3B5FE5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          color: baseColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
