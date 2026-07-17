import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreditpointScreen extends StatefulWidget {
  const CreditpointScreen({super.key});

  @override
  State<CreditpointScreen> createState() => _CreditpointScreenState();
}

class _CreditpointScreenState extends State<CreditpointScreen> {
  Map<String, dynamic>? plan;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  bool isBuying = false;

  final TextEditingController _amountController = TextEditingController();
  int previewPoints = 0;

  String filterType = 'all';
  String? startDate;
  String? endDate;
  bool isload = false;
  String dateLabel = Translate.t("filter.SelectDate");
  Map<String, dynamic> user = {};
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    getuserprofile();
    _fetchPlan();
    _fetchWalletHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> getuserprofile() async {
    userData = await SecureStorageService.getUserData();
    final userId = userData['_id'];
    FilterRequest request = FilterRequest(userId: userId);
    context.read<ProfileProvider>().userprofilefetch(
      endpoint: "entities/filter/users",
      filterPayload: request.getuserprofile(),
    );
    userData = await SecureStorageService.getUserProfileData();
    setState(() {
      user = userData;
    });
  }

  // --- API Logic (Kept same as your previous working version) ---
  Future<void> _fetchPlan() async {
    try {
      final PostService api = PostService();
      final res = await api.getPosts(
        endpoint: 'entities/filter/settings',
        data: {},
      );
      if (res['status'] == 200) {
        final response = res['data']?[0]?['response'];
        if (response != null && (response as List).isNotEmpty) {
          setState(() => plan = Map<String, dynamic>.from(response[0]));
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch plan: $e');
    }
  }

  Future<void> _fetchWalletHistory() async {
    setState(() => isLoading = true);
    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id']?.toString() ?? '';
      final List<Map<String, dynamic>> conditions = [
        {'column': 'user_id', 'operator': 'EQUALS', 'value': userId},
      ];
      if (filterType != 'all') {
        conditions.add({
          'column': 'type',
          'operator': 'EQUALS',
          'value': filterType,
        });
      }
      if (startDate != null && endDate != null) {
        conditions.addAll([
          {
            'column': 'created_on',
            'operator': 'GREATERTHANOREQUAL',
            'type': 'date',
            'value': startDate,
          },
          {
            'column': 'created_on',
            'operator': 'LESSTHANOREQUAL',
            'type': 'date',
            'value': endDate,
          },
        ]);
      }
      final filterPayload = {
        'filterParams': [
          {
            'parmasName': 'user_ref_id',
            'parmsDataType': 'string',
            'paramsValue': userId,
          },
        ],
        'filter': [
          {'clause': 'AND', 'conditions': conditions},
        ],
        'sort': [
          {'sort': 'desc', 'colId': 'created_on'},
        ],
      };
      final PostService api = PostService();
      final res = await api.getPosts(
        endpoint: 'dataset/data/wallet_history',
        data: filterPayload,
      );
      if (res['status'] == 200) {
        final dynamic rawData = res['data'];
        final dynamic firstItem = (rawData is List && rawData.isNotEmpty)
            ? rawData[0]
            : null;
        final dynamic rawResponse = firstItem is Map
            ? firstItem['response']
            : null;
        final List<Map<String, dynamic>> rows = [];
        if (rawResponse is List) {
          for (final e in rawResponse) {
            if (e is Map) rows.add(Map<String, dynamic>.from(e));
          }
        }
        await SettingsLocalRepository.instance.clearTransactionSettings();
        await SettingsLocalRepository.instance.saveTransactionSettings(rows);
        setState(() {
          transactions = rows;
        });
      }
    } catch (e) {
      debugPrint('History fetch error: $e');
    } finally {
      final rows = await SettingsLocalRepository.instance
          .getTransactionSettings();
      setState(() {
        isLoading = false;
        transactions = rows;
      });
    }
  }

  String _formatDate(dynamic dateVal) {
    try {
      DateTime d = (dateVal is Map && dateVal['\$date'] != null)
          ? DateTime.parse(dateVal['\$date'].toString()).toLocal()
          : DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(d);
    } catch (_) {
      return '—';
    }
  }

  String _getMonthYear(dynamic dateVal) {
    try {
      DateTime d = (dateVal is Map && dateVal['\$date'] != null)
          ? DateTime.parse(dateVal['\$date'].toString()).toLocal()
          : DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('MMMM yyyy').format(d).toUpperCase();
    } catch (_) {
      return '—';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByMonth() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final transaction in transactions) {
      final monthYear = _getMonthYear(transaction['created_on']);
      grouped.putIfAbsent(monthYear, () => []).add(transaction);
    }
    return grouped;
  }

  Future<void> _pickDateRange() async {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      minimumDate: DateTime.now().subtract(const Duration(days: 365)),
      maximumDate: DateTime.now(),
      backgroundColor: AppColors.surfaceLight,
      primaryColor: AppColors.primary,
      onApplyClick: (start, end) {
        setState(() {
          startDate = start.toUtc().toIso8601String();
          endDate = end.add(const Duration(days: 1)).toUtc().toIso8601String();
          dateLabel =
              "${DateFormat('dd/MM/yy').format(start)} - ${DateFormat('dd/MM/yy').format(end)}";
        });
        _fetchWalletHistory();
      },
      onCancelClick: () {
        setState(() {
          startDate = null;
          endDate = null;
          dateLabel = "Filter Date Range";
        });
        _fetchWalletHistory();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('CreditPoint', context);
    final phone = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translate.t("creditScreen.Transaction_History"),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // actions: [
        //   if (!phone) ...[
        //     Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: Container(
        //         decoration: BoxDecoration(
        //           color: AppColors.background.withValues(alpha: 0.15),
        //           borderRadius: BorderRadius.circular(12),
        //           border: Border.all(
        //             color: AppColors.primary.withValues(alpha: 0.2),
        //           ),
        //         ),
        //         child: GestureDetector(
        //           onTap: () {
        //             context.push(RoutePath.creditpayment);
        //           },
        //           child: Padding(
        //             padding: const EdgeInsets.all(4.0),
        //             child: Text(
        //               'Bal pts: ${Formatters.formatTomoney('${user['points'] ?? 0}')}',
        //               style: TextStyle(
        //                 color: AppColors.textSecondary,
        //                 fontSize: 16,
        //                 fontWeight: FontWeight.bold,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //     Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: Container(
        //         decoration: BoxDecoration(
        //           color: AppColors.primary.withValues(alpha: 0.10),
        //           borderRadius: BorderRadius.circular(12),
        //           border: Border.all(
        //             color: AppColors.primary.withValues(alpha: 0.2),
        //           ),
        //         ),
        //         child: GestureDetector(
        //           onTap: () {
        //             context.push(RoutePath.creditpayment).then((_) {
        //               _fetchWalletHistory();
        //             });
        //           },
        //           child: Padding(
        //             padding: const EdgeInsets.all(4.0),
        //             child: Row(
        //               children: [
        //                 Icon(
        //                   Icons.add,
        //                   color: AppColors.accent,
        //                   size: 24,
        //                   fontWeight: FontWeight.bold,
        //                 ),
        //                 const SizedBox(width: 8),
        //                 Text(
        //                   "Buy points",
        //                   style: AppTextThemes.getLightTextTheme.displaySmall!
        //                       .copyWith(
        //                         color: AppColors.accent,
        //                         fontWeight: FontWeight.bold,
        //                       ),
        //                 ),
        //                 const SizedBox(width: 8),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ],
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            CreditBalanceCard(
              creditBalance: int.parse('${user['points'] ?? 0}'),
              onAddCredits: () {
                context.push(RoutePath.creditpayment).then((_) {
                  getuserprofile();
                  _fetchWalletHistory();
                });
              },
            ),

            _buildfilterCard(phone),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : isload
                ? const Center(child: CircularProgressIndicator())
                : _buildTransactionHistoryByDate(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildfilterCard(bool phone) {
    return // Filter Tabs and Date Range
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: phone
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'All',
                        isSelected: filterType == 'all',
                        onTap: () {
                          setState(() => filterType = 'all');
                          _fetchWalletHistory();
                        },
                      ),
                      _FilterTab(
                        label: 'Credits',
                        isSelected: filterType == 'CR',
                        onTap: () {
                          setState(() => filterType = 'CR');
                          _fetchWalletHistory();
                        },
                      ),
                      _FilterTab(
                        label: 'Debits',
                        isSelected: filterType == 'DR',
                        onTap: () {
                          setState(() => filterType = 'DR');
                          _fetchWalletHistory();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.borderLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        _FilterTab(
                          label: 'All',
                          isSelected: filterType == 'all',
                          onTap: () {
                            setState(() => filterType = 'all');
                            _fetchWalletHistory();
                          },
                        ),
                        _FilterTab(
                          label: 'Credits',
                          isSelected: filterType == 'CR',
                          onTap: () {
                            setState(() => filterType = 'CR');
                            _fetchWalletHistory();
                          },
                        ),
                        _FilterTab(
                          label: 'Debits',
                          isSelected: filterType == 'DR',
                          onTap: () {
                            setState(() => filterType = 'DR');
                            _fetchWalletHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// NEW: Transaction History Grouped by Date
  Widget _buildTransactionHistoryByDate() {
    final groupedTransactions = _groupTransactionsByMonth();

    if (groupedTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            "No transactions found",
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final entry = groupedTransactions.entries.elementAt(index);
        final monthYear = entry.key;
        final monthTransactions = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Header
              Text(
                monthYear,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Transactions in this month
              ...monthTransactions.map((transaction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _buildTransactionItem(transaction),
                );
              }).toList(),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // String postid = "";
  Future<String> getpostid(Map<String, dynamic> row) async {
    try {
      setState(() {
        isload = true;
      });
      ApiDioGetService service = ApiDioGetService();
      final response = await service.getdata(
        endpoint: "/entities/response/${row["ref_id"]}",
      );
      if (response['status'] == 200) {
        final responseData = response['data'];
        final post = responseData[0];
        final postid = post['stockId'] ?? post["requirementId"] ?? "";
        setState(() {
          isload = false;
        });
        return postid;
      }
      setState(() {
        isload = false;
      });
      return " ";
    } catch (e) {
      debugPrintStack();
      setState(() {
        isload = false;
      });
      return " ";
    }
  }

  /// IMPROVED TRANSACTION ITEM - New Professional Design
  Widget _buildTransactionItem(Map<String, dynamic> row) {
    final bool isCR = row['type'] == 'CR';
    final int amount = (row['amount'] as num?)?.toInt() ?? 0;
    final int opening = (row['opening_balance'] as num?)?.toInt() ?? 0;
    final int closing = (row['closing_balance'] as num?)?.toInt() ?? 0;

    // Determine icon and color based on label
    IconData icon = isCR ? Icons.payment_outlined : Icons.payments_outlined;
    Color iconBg = isCR ? AppColors.success : AppColors.error;

    final label = (row['display_label'] ?? '').toString().toLowerCase();
    if (label.contains('requirements')) {
      icon = Icons.shopping_cart_sharp;
      iconBg = AppColors.success;
    } else if (label.contains('stocks') || label.contains('logistics')) {
      icon = Icons.local_shipping_rounded;
      iconBg = AppColors.error;
    } else if (label.contains('warehouse') || label.contains('deposit')) {
      icon = Icons.warehouse_rounded;
      iconBg = AppColors.success;
    } else if (label.contains('tax') || label.contains('repayment')) {
      icon = Icons.receipt_rounded;
      iconBg = AppColors.error;
    }

    final description =
        (row['description'] == 'Posted to requirements' ||
            row['description'] == 'Posted to stocks'
        ? "${row['header'] ?? row['description'] ?? ""}"
        : row['description'] == 'Posted to quotes' ||
              row['description'] == 'Posted to stock_quotes'
        ? '${row['header'] ?? row['description'] ?? ""}'
        : row['header'] == ''
        ? 'Credit points'
        : '${row['header'] ?? row['description'] ?? "Credit points"}');
    final path = row['description'] == 'Posted to requirements'
        ? RoutePath.postBuyer
        : row['description'] == 'Posted to stocks'
        ? RoutePath.postSeller
        : row['description'] == 'Posted to quotes'
        ? RoutePath.sellerResponseviewscreen
        : row['description'] == 'Posted to stock_quotes'
        ? RoutePath.buyerResponseviewscreen
        : "";

    return GestureDetector(
      onTap: () async {
        if (isCR) {
          // Handle credit transaction tap
        } else {
          if (path == RoutePath.postBuyer || path == RoutePath.postSeller) {
            context.push(path, extra: '${row["ref_id"]}');
          } else if (path == RoutePath.buyerResponseviewscreen ||
              path == RoutePath.sellerResponseviewscreen) {
            String postid = await getpostid(row);
            context.push(path, extra: [postid, '${row["ref_id"]}']);
          }
          // Handle debit transaction tap
        }
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width < 900 ? null : 900,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(row['created_on']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── CR / DR Badge ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCR
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCR
                        ? 'Purchased'
                        : description.contains("Post")
                        ? "Post"
                        : 'Response',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCR ? AppColors.success : AppColors.error,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 12),

            // ── Ledger Row: Opening → Delta → Closing ───────────────────
            IntrinsicHeight(
              child: Row(
                children: [
                  // Opening Balance
                  Expanded(
                    child: _LedgerCell(
                      label: 'Opening pts',
                      value: NumberFormat('#,##,##0').format(opening),
                      align: CrossAxisAlignment.start,
                    ),
                  ),

                  // Vertical divider
                  VerticalDivider(color: AppColors.borderLight, width: 1),

                  // Delta (Credited / Redeemed)
                  Expanded(
                    child: _LedgerCell(
                      label: isCR ? 'Purchased pts' : 'Redeemed pts',
                      value:
                          '${isCR ? '+' : '−'} ${NumberFormat('#,##,##0').format(amount)}',
                      valueColor: isCR ? AppColors.success : AppColors.error,
                      valueFontSize: 14,
                      align: CrossAxisAlignment.center,
                    ),
                  ),

                  // Vertical divider
                  VerticalDivider(color: AppColors.borderLight, width: 1),

                  // Closing Balance
                  Expanded(
                    child: _LedgerCell(
                      label: 'Closing pts',
                      value: NumberFormat('#,##,##0').format(closing),
                      align: CrossAxisAlignment.end,
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

class _LedgerCell extends StatelessWidget {
  const _LedgerCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize = 15,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final double valueFontSize;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
// --- Internal Helper Widgets ---

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
