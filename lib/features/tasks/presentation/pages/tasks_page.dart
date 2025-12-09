import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({
    super.key,
    required this.language,
  });

  final AppLanguage language;

  String _translate(String vi, String en) =>
      language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_box_outlined,
              size: 48,
              color: const Color(0xFFCBD5F0),
            ),
            const SizedBox(height: 12),
            Text(
              _translate('Công việc', 'My Tasks'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2A37),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(
                _translate(
                  'Tính năng đang được xây dựng.',
                  'This area is coming soon.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
