import 'package:cashew_marketplace/core/providers/blocked_user_provider.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/models/blocked_user_model.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/widgets/blocked_user_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<BlockedUser> _blockedUsers = [];
  Set<String> _unblockingIds = {};
  Map<String, dynamic> userData = {}; // Track which users are being unblocked

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  /// Fetch all blocked users
  Future<void> _fetchBlockedUsers() async {
    if (!mounted) return;

    try {
      if (!mounted) return;
      userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      FilterRequest request = FilterRequest(userId: userId);
      await context.read<BlockedUserProvider>().fetch(
        endpoint: "dataset/data/blocked_user",
        filterPayload: request.getblockeduser(),
      );
    } catch (e) {
      if (!mounted) return;
    }
  }

  /// Unblock a specific user
  Future<void> _unblockUser(String userId, String id) async {
    if (!mounted) return;
    // Add to loading set

    try {
      if (!mounted) return;
      final postService = ApiDioPostService();
      await postService.deletedata(
        endpoint: "entities/blocked/$id",
        data: {"userId": userData['_id'], "block_id": userId},
      );
      _fetchBlockedUsers();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User unblocked successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrintStack();
    }
  }

  /// Show confirmation dialog before unblocking
  void _showUnblockConfirmation(BlockedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Translate.t("blocked.Unblock_User"),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ],
        ),
        content: Text(
          '${Translate.t("blocked.message")} ${user.name}?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              context.pop();
              _unblockUser(user.raw['block_id'], user.id);
            },
            child: Text(Translate.t("blocked.unblock")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<BlockedUserProvider>(
        builder: (context, provider, child) {
          _blockedUsers = provider.blockedusers;
          if (provider.isloading) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => const BlockedUserCardSkeleton(),
            );
          }

          // Empty state
          if (_blockedUsers.isEmpty) {
            return const EmptyBlockedUsersState();
          }

          // List state
          return ListView.builder(
            itemCount: _blockedUsers.length,
            itemBuilder: (context, index) {
              final user = _blockedUsers[index];
              final isUnblocking = _unblockingIds.contains(user.id);

              return BlockedUserCard(
                user: user,
                isUnblocking: isUnblocking,
                onUnblock: () => _showUnblockConfirmation(user),
              );
            },
          );
        },
      ),
    );
  }

  /// Build AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        Translate.t("blocked.blocked_user"),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Consumer<BlockedUserProvider>(
              builder: (context, provider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.blockedusers.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build main body based on sta
}
