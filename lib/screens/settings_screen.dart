import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with TickerProviderStateMixin {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoUpload = false;
  bool _highQuality = true;
  String _units = 'Inches';
  String _language = 'English';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios, size: 20),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Customize your experience',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Settings Content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Camera Settings Section
                      _buildSection(
                        title: 'Camera Settings',
                        icon: Icons.camera_alt,
                        color: Colors.blue,
                        children: [
                          _buildSwitchTile(
                            title: 'High Quality Mode',
                            subtitle: 'Better accuracy with larger file sizes',
                            value: _highQuality,
                            onChanged: (value) => setState(() => _highQuality = value),
                            icon: Icons.hd,
                          ),
                          _buildSwitchTile(
                            title: 'Auto Upload',
                            subtitle: 'Automatically upload when online',
                            value: _autoUpload,
                            onChanged: (value) => setState(() => _autoUpload = value),
                            icon: Icons.cloud_upload,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Measurement Settings Section
                      _buildSection(
                        title: 'Measurements',
                        icon: Icons.straighten,
                        color: Colors.green,
                        children: [
                          _buildDropdownTile(
                            title: 'Units',
                            subtitle: 'Measurement units preference',
                            value: _units,
                            items: ['Inches', 'Centimeters'],
                            onChanged: (value) => setState(() => _units = value!),
                            icon: Icons.straighten,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // App Settings Section
                      _buildSection(
                        title: 'App Settings',
                        icon: Icons.settings,
                        color: Colors.purple,
                        children: [
                          _buildSwitchTile(
                            title: 'Dark Mode',
                            subtitle: 'Switch to dark theme',
                            value: _darkMode,
                            onChanged: (value) => setState(() => _darkMode = value),
                            icon: Icons.dark_mode,
                          ),
                          _buildSwitchTile(
                            title: 'Notifications',
                            subtitle: 'Receive app notifications',
                            value: _notifications,
                            onChanged: (value) => setState(() => _notifications = value),
                            icon: Icons.notifications,
                          ),
                          _buildDropdownTile(
                            title: 'Language',
                            subtitle: 'App language preference',
                            value: _language,
                            items: ['English', 'Spanish', 'French', 'German'],
                            onChanged: (value) => setState(() => _language = value!),
                            icon: Icons.language,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Data & Privacy Section
                      _buildSection(
                        title: 'Data & Privacy',
                        icon: Icons.security,
                        color: Colors.orange,
                        children: [
                          _buildActionTile(
                            title: 'Clear Cache',
                            subtitle: 'Free up storage space',
                            icon: Icons.cleaning_services,
                            onTap: () => _showClearCacheDialog(),
                          ),
                          _buildActionTile(
                            title: 'Export Data',
                            subtitle: 'Download your measurement data',
                            icon: Icons.download,
                            onTap: () => _showExportDialog(),
                          ),
                          _buildActionTile(
                            title: 'Privacy Policy',
                            subtitle: 'View our privacy policy',
                            icon: Icons.privacy_tip,
                            onTap: () => _showPrivacyPolicy(),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // About Section
                      _buildSection(
                        title: 'About',
                        icon: Icons.info,
                        color: Colors.indigo,
                        children: [
                          _buildInfoTile(
                            title: 'Version',
                            subtitle: '1.0.0',
                            icon: Icons.info_outline,
                          ),
                          _buildActionTile(
                            title: 'Help & Support',
                            subtitle: 'Get help and contact support',
                            icon: Icons.help_outline,
                            onTap: () => _showSupportDialog(),
                          ),
                          _buildActionTile(
                            title: 'Rate App',
                            subtitle: 'Rate us on the app store',
                            icon: Icons.star_outline,
                            onTap: () => _showRatingDialog(),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Cache'),
        content: Text('This will delete all cached images and temporary files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Export Data'),
        content: Text('Export your measurement history as CSV or PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement CSV export
            },
            child: Text('CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement PDF export
            },
            child: Text('PDF'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    // Navigate to privacy policy screen or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text('Your privacy policy content goes here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Support'),
              subtitle: Text('support@smarttailoring.com'),
              onTap: () {
                // Launch email
              },
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone Support'),
              subtitle: Text('+1 (555) 123-4567'),
              onTap: () {
                // Launch phone
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rate Our App'),
        content: Text('Would you like to rate Smart Tailoring on the app store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch app store rating
            },
            child: Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}