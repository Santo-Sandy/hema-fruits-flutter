import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/features/screens/activity/post_requiremment/my_post_screen.dart';
import 'package:cashew_marketplace/features/screens/activity/enquiry/my_enquiry_screen.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/widgets/activity_page_controls.dart';
import 'package:flutter/material.dart';

class MyActivityScreen extends StatefulWidget {
  final int initialTab;
  final String? type;

  const MyActivityScreen({super.key, this.type, required this.initialTab});
  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  late int _selectedPage;
  late final ActivityFilterController _filterController;
  late final ActivitySortController _sortController;

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.initialTab.clamp(0, 1).toInt();
    _filterController = ActivityFilterController()
      ..setActivePage(_selectedPage);
    _sortController = ActivitySortController()..setActivePage(_selectedPage);
  }

  @override
  void dispose() {
    _filterController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MyActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newPage = widget.initialTab.clamp(0, 1).toInt();
    if (newPage != oldWidget.initialTab || widget.type != oldWidget.type) {
      setState(() {
        _selectedPage = newPage;
      });
      _filterController.setActivePage(_selectedPage);
      _sortController.setActivePage(_selectedPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ActivityPageOption(
        value: 0,
        label: Translate.t("tabs.my_post"),
        icon: Icons.my_library_books_outlined,
      ),
      ActivityPageOption(
        value: 1,
        label: Translate.t("tabs.enquiries"),
        icon: Icons.chat_bubble_outline,
      ),
    ];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            border: Border(
              bottom: BorderSide(color: AppColors.primaryDark, width: 1),
            ),
          ),
          child: ActivityPageToolbar(
            selectedPage: _selectedPage,
            pages: pages,
            filterController: _filterController,
            sortController: _sortController,
            onPageChanged: (page) {
              setState(() => _selectedPage = page);
              _filterController.setActivePage(page);
              _sortController.setActivePage(page);
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedPage,
            children: [
              MyPostAndResponse(
                type: widget.type,
                showInlineFilters: false,
                filterController: _filterController,
                filterPageIndex: 0,
                sortController: _sortController,
                sortPageIndex: 0,
              ),
              MyEnquiryScreen(
                type: widget.type,
                showInlineFilters: false,
                filterController: _filterController,
                filterPageIndex: 1,
                sortController: _sortController,
                sortPageIndex: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
