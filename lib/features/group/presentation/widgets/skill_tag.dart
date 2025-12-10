import 'package:flutter/material.dart';

class SkillTag extends StatelessWidget {
  final String skill;

  const SkillTag({
    super.key,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3A6FD8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
