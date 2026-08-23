import 'package:flutter/material.dart';

import '../theme/forestring_theme.dart';

class StudentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const StudentAppBar({
    super.key,
    this.title = '포레스트링 수강생',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'ELAND',
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
      ),
    );
  }
}

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({
    super.key,
    required this.displayName,
    required this.onHome,
    required this.onReschedule,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onHome;
  final VoidCallback onReschedule;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$displayName 님',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ELAND',
                      fontWeight: FontWeight.w300,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.home_filled,
                color: primaryColor,
              ),
              title: const Text(
                '메인페이지',
                style: forestringTextStyle,
              ),
              trailing: const Icon(Icons.navigate_next_rounded),
              onTap: onHome,
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month_rounded,
                color: primaryColor,
              ),
              title: const Text(
                '예약 변경하기',
                style: forestringTextStyle,
              ),
              trailing: const Icon(Icons.navigate_next_rounded),
              onTap: onReschedule,
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                '로그아웃',
                style: forestringTextStyle.copyWith(
                  color: Colors.redAccent,
                ),
              ),
              onTap: onLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
