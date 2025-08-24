import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildProfileSection(),
            const SizedBox(height: 30),
            _buildSectionHeader('Account'),
            _buildSettingsItem(Icons.person_outline, 'Personal info'),
            _buildSettingsItem(Icons.payment, 'Payments & payouts'),
            _buildSettingsItem(Icons.notifications_none, 'Notifications'),
            _buildSettingsItem(Icons.lock_outline, 'Privacy & sharing'),
            const SizedBox(height: 30),
            _buildSectionHeader('Referrals & Credits'),
            _buildSettingsItem(
              Icons.card_giftcard,
              'Gift cards',
              subtitle: 'Send or redeem a gift card',
            ),
            _buildSettingsItem(
              Icons.people_outline,
              'Refer a friend',
              subtitle: 'Earn \$20 for every friend you refer',
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('Support'),
            _buildSettingsItem(
              Icons.shield_outlined,
              'Safety Center',
              subtitle: 'Get the support, tools, and info you need to be safe.',
            ),
            _buildSettingsItem(
              Icons.headset_mic_outlined,
              'Contact Support',
              subtitle: 'Let our team know about your concerns.',
            ),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(
            'https://placehold.co/100x100/orange/white?text=E',
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dhanno',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('View profile', style: TextStyle(color: Colors.white)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? subtitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 130, 182, 255),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white70))
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: () {},
    );
  }
}
