import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:jeokissan_5t_quality_management_system/faq_screen.dart';
import 'package:jeokissan_5t_quality_management_system/locale_provider.dart';
import 'package:jeokissan_5t_quality_management_system/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }
    }
    return 'User';
  }

  String _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  Future<void> _handleSignOut() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.signOut),
        content: Text(loc.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserDisplayName();
    final userEmail = _getUserEmail();
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.settings,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ==========================================
          // Profile Header (Dynamic)
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (userEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ==========================================
          // About Section
          // ==========================================
          _sectionTitle(loc.about),
          _settingsTile(Icons.business, loc.aboutThathalITS, onTap: () {
            launchUrl(Uri.parse('https://www.thathalits.com/about'), mode: LaunchMode.externalApplication);
          }),
          _settingsTile(Icons.eco, loc.aboutGeoKissan, onTap: () {
            launchUrl(Uri.parse('https://www.jeokissan.com/about-us'), mode: LaunchMode.externalApplication);
          }),
          const Divider(height: 1),

          // ==========================================
          // Help Section (unchanged)
          // ==========================================
          _sectionTitle(loc.help),
          _settingsTile(Icons.school, loc.gettingStartedGuide, onTap: () {}),
          _settingsTile(Icons.help_outline, loc.frequentlyAskedQuestions, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FAQScreen()),
            );
          }),
          _settingsTile(Icons.support_agent, loc.contactSupport, onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.contactSupport,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                      title: const Text('0330 5077719'),
                      subtitle: Text(loc.tapToCall),
                      onTap: () {
                        launchUrl(Uri.parse('tel:03305077719'));
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email, color: Color(0xFF4CAF50)),
                      title: const Text('jeokissan@gmail.com'),
                      subtitle: Text(loc.tapToSendEmail),
                      onTap: () {
                        launchUrl(Uri.parse('mailto:jeokissan@gmail.com'));
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 1),

          const SizedBox(height: 16),

          // ==========================================
          // Language Selector #
          // ==========================================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF4CAF50), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.language,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: localeProvider.isUrdu ? 'Urdu' : 'English',
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Urdu', child: Text('اردو')),
                    ],
                    onChanged: (value) {
                      if (value == 'Urdu') {
                        localeProvider.switchToUrdu();
                      } else {
                        localeProvider.switchToEnglish();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==========================================
          // Sign Out Button
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                label: Text(
                  loc.signOut,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // App Version
          // ==========================================
          Center(
            child: Text(
              '6.1.1.2797',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
