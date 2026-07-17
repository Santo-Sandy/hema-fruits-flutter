import 'package:cashew_marketplace/core/services/offline_queue_service.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key});

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> {
  List<QueuedApiRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    OfflineQueueService.onQueueFlushed.addListener(_load);
    OfflineQueueService.queueChanged.addListener(_load);
  }

  @override
  void dispose() {
    OfflineQueueService.onQueueFlushed.removeListener(_load);
    OfflineQueueService.queueChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final all = await OfflineQueueService.instance.getPendingRequests();
    if (!mounted) return;
    setState(() {
      _items = all.where(OfflineQueueService.isVisible).toList();
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    await OfflineQueueService.instance.removeRequest(id);
    await _load();
  }

  /// Human-readable label for the 4 visible action types.
  String _label(QueuedApiRequest item) {
    final data = item.data ?? {};
    switch (item.actionType) {
      case 'dynamicPost':
        if (data['quantity'] != null) {
          return 'Response';
        }
        return 'Posting';
      case 'submitResponse':
        return 'Response';
      case 'updateProfile':
        final data = item.data ?? {};
        return data['iscompany'] == true
            ? 'Business Updating'
            : 'Profile Updating';
      default:
        return item.actionType ?? item.endpoint;
    }
  }

  IconData _icon(QueuedApiRequest item) {
    final data = item.data ?? {};
    switch (item.actionType) {
      case 'dynamicPost':
        if (data['quantity'] != null) {
          return Icons.message_outlined;
        }
        return Icons.inventory_2_outlined;
      case 'submitResponse':
        return Icons.mark_email_unread_outlined;
      case 'updateProfile':
        final data = item.data ?? {};
        return data['iscompany'] == true
            ? Icons.business_outlined
            : Icons.person_outline;
      default:
        return Icons.schedule_outlined;
    }
  }

  String _subtitle(QueuedApiRequest item) {
    final data = item.data ?? {};
    if (item.actionType == 'dynamicPost') {
      if (data['quantity'] != null) {
        final qty = Formatters.formatToKg(data['quantity'] ?? '');
        final price = Formatters.formatTomoney(
          data['expectedPrice'] ?? data['priceperKg'] ?? '',
        );

        final currency = getCurrencySymbol(data['currency']?.toString() ?? "");
        return [
          if (qty != '') 'Qty: $qty',
          if (price != '') 'Price: $currency $price',
        ].join(' · ');
      }
      final grade = data['grade'] ?? data['productGrade'] ?? '';
      final qty = Formatters.formatToKg(
        data['availableqty'] ?? data['requiredqty'] ?? '',
      );
      final type = data['type'] ?? '';
      return [
        type,
        if (grade != '') grade.toString(),
        if (qty != '') qty.toString(),
      ].join(' · ');
    }
    if (item.actionType == 'submitResponse') {
      final qty = data['quantity'] ?? '';
      final price = data['expectedPrice'] ?? data['priceperKg'] ?? '';
      final currency = getCurrencySymbol(data['currency']?.toString() ?? "");
      return [
        if (qty != '') 'Qty: $qty',
        if (price != '') 'Price: $currency $price',
      ].join(' · ');
    }
    if (item.actionType == 'updateProfile') {
      final name = data['name'] ?? data['companyName'] ?? '';
      return name.toString();
    }
    return '';
  }

  Future<void> _uploadNow(String id) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Uploading...')));
    try {
      final resp = await OfflineQueueService.instance.executeRequestById(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp == null
                ? 'Upload deferred (offline)'
                : 'Uploaded successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<({bool uploading, int count})>(
          valueListenable: OfflineQueueService.uploadState,
          builder: (context, state, _) => Text(
            state.uploading
                ? 'Uploading ${state.count} item${state.count == 1 ? '' : 's'}...'
                : 'Waiting for upload (${_items.length})',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Text(
                'No pending items',
                style: AppTextThemes.getLightTextTheme.titleMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = _items[index];
                final subtitle = _subtitle(item);
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _icon(item),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _label(item),
                    style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: subtitle.isNotEmpty
                      ? Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextThemes.getLightTextTheme.bodySmall,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.success,
                        ),
                        onPressed: () => _uploadNow(item.id),
                        tooltip: 'Upload now',
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.error),
                        onPressed: () => _remove(item.id),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
