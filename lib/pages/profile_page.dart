import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../state/finance_app_state.dart';
import '../widgets/pin_entry_sheet.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.email ?? 'Your Profile',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your expenses are private to this account.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.currency_exchange,
            title: 'Select Currency',
            subtitle: 'Choose the default currency used throughout the app',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          _ProfileActionTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Control your account security',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PrivacyPage())),
          ),
          _ProfileActionTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Manage spending alerts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            ),
          ),
          _ProfileActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpSupportPage())),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _signOut(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message ?? 'Could not sign out. Try again.');
    }
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: state.paymentNotificationsEnabled,
            onChanged: state.setPaymentNotificationsEnabled,
            title: const Text('Planned payment reminders'),
            subtitle: const Text('Remind me when a payment is due.'),
          ),
          SwitchListTile(
            value: state.budgetNotificationsEnabled,
            onChanged: state.setBudgetNotificationsEnabled,
            title: const Text('Budget alerts'),
            subtitle: const Text('Alert me when spending approaches a limit.'),
          ),
        ],
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _LockTypeTile(
            icon: Icons.lock_open_outlined,
            title: 'None',
            subtitle: 'No app lock required.',
            selected: state.lockType == LockType.none,
            onTap: () async {
              final changed = await state.setLockType(LockType.none);
              if (!context.mounted || changed) return;
              _showMessage(context, 'Could not turn off the app lock.');
            },
          ),
          _LockTypeTile(
            icon: Icons.fingerprint,
            title: 'Biometric',
            subtitle: 'Fingerprint or face recognition.',
            selected: state.lockType == LockType.biometric,
            onTap: () async {
              final changed = await state.setLockType(LockType.biometric);
              if (!context.mounted || changed) return;
              _showMessage(
                context,
                'Biometric authentication was cancelled or is unavailable.',
              );
            },
          ),
          _LockTypeTile(
            icon: Icons.pin_outlined,
            title: 'PIN',
            subtitle: 'A 4-digit code stored only on this device.',
            selected: state.lockType == LockType.pin,
            onTap: () async {
              final pin = await showPinEntrySheet(
                context,
                title: 'Set your PIN',
                confirmPin: true,
                cancelLabel: 'Cancel',
              );
              if (pin == null) return;
              if (!context.mounted) return;
              final changed = await state.setLockType(LockType.pin, pin: pin);
              if (!context.mounted || changed) return;
              _showMessage(context, 'Could not set the PIN.');
            },
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.cloud_done_outlined),
            title: Text('Private cloud sync'),
            subtitle: Text(
              'Your synced data is only accessible to your verified account.',
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _LockTypeTile extends StatelessWidget {
  const _LockTypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF59E0B);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? accent : const Color(0xFF9CA3AF),
        ),
        onTap: onTap,
      ),
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & Support')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.menu_book_outlined),
          title: Text('Getting started'),
          subtitle: Text(
            'Add transactions, create budgets, and set savings goals.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.sync_outlined),
          title: Text('Sync and offline use'),
          subtitle: Text(
            'Changes are stored on this device and synced when you reconnect.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.email_outlined),
          title: Text('Contact support'),
          subtitle: Text(
            'Email support from the account registered with this app.',
          ),
        ),
      ],
    ),
  );
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
