import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../data/auth_repository.dart';
import '../state/insights.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart' show DemoNotice;

/// Account, appearance (light / dark / system) and sign out.
class ProfileScreen extends StatelessWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('You can sign back in at any time.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AppScope.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.xl,
        ),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.colors.primary,
                  child: Text(
                    user.initials,
                    style: context.text.titleLarge?.copyWith(
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: context.text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ListenableBuilder(
            listenable: AppScope.tasks,
            builder: (context, _) {
              final data = Insights.compute(AppScope.tasks.tasks);
              return AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                child: Row(
                  children: [
                    _Stat('${data.open}', 'Open'),
                    _divider(context),
                    _Stat('${data.done}', 'Completed'),
                    _divider(context),
                    _Stat(
                      '${data.overdue}',
                      'Overdue',
                      color: data.overdue > 0 ? p.danger : null,
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader('Appearance'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Text('Theme', style: context.text.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppScope.theme,
                  builder: (context, mode, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined, size: 18),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined, size: 18),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined, size: 18),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => AppScope.theme.set(s.first),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SectionHeader('Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    kDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(kDemoMode ? 'Demo data' : 'Cloud sync'),
                  subtitle: Text(
                    kDemoMode
                        ? 'Sample tasks stored in memory on this device'
                        : 'Tasks are saved to your account',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: p.danger),
                  title: Text(
                    'Sign out',
                    style: context.text.titleSmall?.copyWith(color: p.danger),
                  ),
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ),
          if (kDemoMode) ...[
            const SizedBox(height: AppSpace.lg),
            const DemoNotice(
              'You are using the demo build. Changes reset when the app restarts.',
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Center(
            child: Text('Tasky 1.0.0', style: context.text.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 36, color: context.palette.border);
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _Stat(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: context.text.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
