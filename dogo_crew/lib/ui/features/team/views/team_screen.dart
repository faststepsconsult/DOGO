import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/crew_repository.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/team_view_model.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TeamViewModel(crewRepo: ctx.read<CrewRepository>()),
      child: const _TeamContent(),
    );
  }
}

class _TeamContent extends StatelessWidget {
  const _TeamContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeamViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currentUserId = authVm.currentUser?.id;

    if (!authVm.isDispatcher) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crew')),
        body: const Center(child: Text('Dispatchers only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Crew Management',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : RefreshIndicator(
              onRefresh: () => vm.loadMembers(),
              color: AppColors.brand,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Crew Roles',
                    style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only approved drivers and dispatchers can access trips and customer details.',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Pending Banner
                  if (vm.pendingApproval.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions_rounded, color: AppColors.gold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${vm.pendingApproval.length} new registered members awaiting approval.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Members List
                  ...vm.members.map((m) {
                    final isMe = m.id == currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.brand.withAlpha(50),
                                      child: Text(
                                        m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'C',
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandLight,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${m.fullName.isNotEmpty ? m.fullName : 'Unnamed Member'}${isMe ? ' (you)' : ''}',
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          m.phone ?? 'No phone recorded',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (m.isPendingApproval)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.goldBorder),
                                    ),
                                    child: Text(
                                      'Pending',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Text('Driver', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: m.isDriver,
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AppColors.brand,
                                      onChanged: (val) {
                                        vm.toggleRole(userId: m.id, role: 'driver', grant: val);
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Dispatcher', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: m.isDispatcher,
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AppColors.brand,
                                      onChanged: isMe
                                          ? null // Cannot revoke own dispatcher role
                                          : (val) {
                                              vm.toggleRole(userId: m.id, role: 'dispatcher', grant: val);
                                            },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
