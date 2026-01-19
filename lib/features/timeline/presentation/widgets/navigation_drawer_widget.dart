import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';

class NavigationDrawerWidget extends StatelessWidget {
  const NavigationDrawerWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.language,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final AppLanguage language;

  String _translate(String vi, String en) =>
      language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _DrawerItem(
        icon: Icons.dashboard_outlined,
        labelVi: 'Tổng quan',
        labelEn: 'Overview',
      ),
      _DrawerItem(
        icon: Icons.people_outline,
        labelVi: 'Điểm đóng góp',
        labelEn: 'Contribute Score',
      ),
      _DrawerItem(
        icon: Icons.feedback_outlined,
        labelVi: 'Phản hồi',
        labelEn: 'Feedback',
      ),
      _DrawerItem(
        icon: Icons.article_outlined,
        labelVi: 'Bài viết',
        labelEn: 'Posts',
      ),
      _DrawerItem(
        icon: Icons.folder_outlined,
        labelVi: 'Tệp',
        labelEn: 'Files',
      ),
    ];

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
      ),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFF5F5F5),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = index == selectedIndex;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        Positioned(
                          left: 0,
                          top: 8,
                          bottom: 8,
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF666666),
                          size: 24,
                        ),
                        title: Text(
                          _translate(item.labelVi, item.labelEn),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () => onItemSelected(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.labelVi,
    required this.labelEn,
  });

  final IconData icon;
  final String labelVi;
  final String labelEn;
}

