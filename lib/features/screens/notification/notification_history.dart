import 'package:hema_fruits/core/providers/notification_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/repositories/notification_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/app_breakpoints.dart';
import 'package:hema_fruits/core/utils/Responsive/app_spacing.dart';
import 'package:hema_fruits/core/utils/Responsive/app_typography.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/theme/app_colors.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<NotificationModel> notifications = [];
  String _selectedFilter = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchnotification();
  }

  Future<void> fetchnotification() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];

      final request = FilterRequest(userId: userId);
      final payload = request.getNotification();

      final provider = context.read<NotificationProvider>();

      await provider.fetch(
        endpoint: "dataset/data/notifications",
        filterPayload: payload,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _getFilteredNotifications() {
    if (_selectedFilter == 'all') {
      return notifications;
    } else if (_selectedFilter == 'stocks') {
      return notifications.where((n) => !n.isRead).toList();
    } else {
      return notifications
          .where((n) => n.type.name == _selectedFilter)
          .toList();
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final service = PostService();
      final result = await service.dynamicPutUpdate(
        collectionName: 'notifications_history',
        id: id,
        data: {'isread': true},
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification marked as read'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    await NotificationRepository.instance.deleteNotification(id);
    await fetchnotification();
  }

  Future<void> _markAllAsRead() async {
    try {
      final service = PostService();
      final unreadNotifications = notifications
          .where((n) => !n.isRead)
          .toList();
      context.read<NotificationProvider>().clearNotifications();
      for (final notification in unreadNotifications) {
        await service.dynamicPutUpdate(
          collectionName: 'notifications_history',
          id: notification.id,
          data: {'isread': true},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    await NotificationRepository.instance.clearNotifications();
    await fetchnotification();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('notifications', context);

    final filteredNotifications = _getFilteredNotifications();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          Translate.t("header.notifications"),
          style: AppTypography.responsive(
            context,
            baseSize: 18,
            tabletSize: 20,
            desktopSize: 22,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, state) {
              if (provider.isloading) {
                return TextButton(
                  onPressed: () {},
                  child: Text(
                    Translate.t("profile.mark_all_read"),
                    style:
                        AppTypography.responsive(
                          context,
                          baseSize: 12,
                          tabletSize: 13,
                          desktopSize: 14,
                        ).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }
              return provider.notifications.isNotEmpty
                  ? TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        Translate.t("profile.mark_all_read"),
                        style:
                            AppTypography.responsive(
                              context,
                              baseSize: 12,
                              tabletSize: 13,
                              desktopSize: 14,
                            ).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                AppBreakpoints.isTabletContext(context) ||
                AppBreakpoints.isDesktopContext(context);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 800 : constraints.maxWidth,
                ),
                child: Column(
                  children: [
                    Consumer<NotificationProvider>(
                      builder: (context, provider, state) {
                        if (provider.isloading &&
                            provider.notifications.isEmpty &&
                            isLoading) {
                          return Expanded(child: _buildEmptyState());
                        }
                        if (provider.notifications.isEmpty) {
                          return Expanded(child: _buildEmptyState());
                        }
                        final notify = provider.notifications;
                        notifications = provider.notifications
                            .map<NotificationModel>(
                              (e) => NotificationModel.fromJson(e),
                            )
                            .toList();
                        return Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? AppSpacing.lg : 0,
                              vertical: AppSpacing.md,
                            ),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];

                              return NotificationCard(
                                onTap: () async {
                                  ContextManager contexts = ContextManager();
                                  final context = contexts.getScreenContext(
                                    contexts.currentPage,
                                  );
                                  if (context == null) {
                                    debugPrint(
                                      "FCM: No context for navigation",
                                    );
                                    return;
                                  }
                                  final datas = notify[index];
                                  final data = datas['metadata'];
                                  final role = context
                                      .read<SwapUserProvider>()
                                      .swapedUser;
                                  SwapUserProvider swapProvider = context
                                      .read<SwapUserProvider>();
                                  if (role != data!['role']) {
                                    // swapProvider.toggleUser();
                                  }
                                  _markAsRead(notification.id);
                                  if (data['name'] == 'quotes') {
                                    final userData =
                                        await SecureStorageService.getUserData();
                                    final userId = userData['_id'] ?? '';
                                    if (userId == data['merchantId']) {
                                      // swapProvider.toggleUser();
                                      context
                                          .push(
                                            RoutePath.sellerResponseviewscreen,
                                            extra: [
                                              "${data['requirementId']}",
                                              "${data['_id']}",
                                            ],
                                          )
                                          .then((_) {
                                            fetchnotification();
                                          });
                                      return;
                                    } else {
                                      //ok
                                      context
                                          .push(
                                            RoutePath.myResponseBuyerpost,
                                            extra: [
                                              "${data['requirementId']}",
                                              "${data['_id']}",
                                            ],
                                          )
                                          .then((_) {
                                            fetchnotification();
                                          });
                                      return;
                                    }
                                  }
                                  if (data['name'] == '/stock') {
                                    // swapProvider.toggleUser();
                                    context
                                        .push(
                                          RoutePath.sellerResponseviewscreen,
                                          extra: [
                                            "${data['requirementId']}",
                                            "${data['_id']}",
                                          ],
                                        )
                                        .then((_) {
                                          fetchnotification();
                                        });
                                  }
                                  if (data['name'] == 'stock_quotes') {
                                    final userData =
                                        await SecureStorageService.getUserData();
                                    final userId = userData['_id'] ?? '';
                                    if (userId == data['buyerId']) {
                                      // swapProvider.toggleUser();
                                      context
                                          .push(
                                            RoutePath.buyerResponseviewscreen,
                                            extra: [
                                              '${data['stockId']}',
                                              '${data['_id']}',
                                            ],
                                          )
                                          .then((_) {
                                            fetchnotification();
                                          });
                                      return;
                                    } else {
                                      //ok
                                      context
                                          .push(
                                            RoutePath.myResponseSellerpost,
                                            extra: [
                                              '${data['stockId']}',
                                              '${data['_id']}',
                                            ],
                                          )
                                          .then((_) {
                                            fetchnotification();
                                          });
                                      return;
                                    }
                                  }
                                  //ok
                                  if (data['name'] == 'stocks') {
                                    context
                                        .push(
                                          RoutePath.viewscreen,
                                          extra: data['_id'],
                                        )
                                        .then((_) {
                                          fetchnotification();
                                        });
                                    return;
                                  }
                                  //ok
                                  if (data['name'] == 'requirements') {
                                    context
                                        .push(
                                          RoutePath.sellerviewscreen,
                                          extra: data['_id'],
                                        )
                                        .then((_) {
                                          fetchnotification();
                                        });
                                    return;
                                  }
                                },
                                notification: notification,
                                onMarkAsRead: () =>
                                    _markAsRead(notification.id),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      ('all', 'All'),
      ('stocks', 'Stocks'),
      ('requirements', 'Requirements'),
      ('quotes', 'Quotes'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.$1;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.$2),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter.$1;
                });
              },
              backgroundColor: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('No notifications'),
        ],
      ),
    );
  }
}
