import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../authentication/domain/entities/user_session.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary,
          child: Text(
            user.name.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(user.role.label, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee ID: ${user.employeeId}'),
                Text('Phone: ${user.phone}'),
                Text('Email: ${user.email}'),
                Text('Account status: ${user.accountStatus}'),
                if (user.store != null)
                  Text('Assigned Store: ${user.store!.name}'),
                if (user.primaryProject != null)
                  Text('Assigned Project: ${user.primaryProject!.name}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push('/sync'),
          child: const Text('View sync status'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password changes must be completed with your administrator.',
                ),
              ),
            );
          },
          child: const Text('Change password'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Log out',
              message: 'You will need internet to sign in again on this device.',
              confirmLabel: 'Logout',
            );
            if (ok && context.mounted) {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            }
          },
          child: const Text('Logout'),
        ),
      ],
    ),
    );
  }
}
