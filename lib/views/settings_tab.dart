import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback? onLogout;

  const SettingsTab({Key? key, this.onLogout}) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _textSize = 1.0;

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
              );
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkModeEnabled
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.green[800]!,
        scaffoldBackgroundColor: Colors.grey[900]!,
        cardColor: Colors.grey[850],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
        dividerColor: Colors.grey[700],
        hintColor: Colors.grey[400],
        iconTheme: const IconThemeData(color: Colors.white70),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.all(Colors.green[800]!.withOpacity(0.5)),
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.green[800]!,
        scaffoldBackgroundColor: Colors.grey[100]!,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black87),
        ),
        dividerColor: Colors.grey[300],
        hintColor: Colors.grey[600],
        iconTheme: const IconThemeData(color: Colors.black54),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.all(Colors.green[800]!.withOpacity(0.5)),
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // App Settings Card
            Card(
              elevation: 4,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('App Settings'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            Icons.notifications,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Enable Notifications'),
                          subtitle: const Text('Receive updates and alerts'),
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Notifications ${_notificationsEnabled ? 'enabled' : 'disabled'}',
                                ),
                              ),
                            );
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        SwitchListTile(
                          secondary: Icon(
                            Icons.dark_mode,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Switch to dark theme for better visibility'),
                          value: _darkModeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Dark mode ${_darkModeEnabled ? 'enabled' : 'disabled'}',
                                ),
                              ),
                            );
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.text_fields,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Text Size',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Slider(
                                  value: _textSize,
                                  min: 0.8,
                                  max: 1.5,
                                  divisions: 7,
                                  label: _textSize.toStringAsFixed(1),
                                  onChanged: (value) {
                                    setState(() {
                                      _textSize = value;
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Card
            Card(
              elevation: 4,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Profile'),
                          subtitle: const Text('View and edit your profile details'),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).hintColor,
                          ),
                          onTap: () {
                            // Navigate to profile page
                          },
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: Icon(
                            Icons.lock,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Change Password'),
                          subtitle: const Text('Update your account password'),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).hintColor,
                          ),
                          onTap: () {
                            // Navigate to change password page
                          },
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          subtitle: const Text('Sign out of your account'),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).hintColor,
                          ),
                          onTap: _showLogoutConfirmationDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About Card
            Card(
              elevation: 4,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('About'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.info,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('App Version'),
                          trailing: Text(
                            '1.0.0',
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: Icon(
                            Icons.description,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Terms of Service'),
                          subtitle: const Text('Read our terms and conditions'),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).hintColor,
                          ),
                          onTap: () {
                            // Navigate to terms page
                          },
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: Icon(
                            Icons.privacy_tip,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Privacy Policy'),
                          subtitle: const Text('Understand how we handle your data'),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).hintColor,
                          ),
                          onTap: () {
                            // Navigate to privacy policy page
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}