import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

class searchbarwidget extends StatefulWidget {
  TextEditingController searchController = TextEditingController();
  Function(String?) onChangedSearch;
  searchbarwidget({
    super.key,
    required this.searchController,
    required this.onChangedSearch,
  });

  @override
  State<searchbarwidget> createState() => _searchbarwidgetState();
}

class _searchbarwidgetState extends State<searchbarwidget> {
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isActive ? AppColors.primary : AppColors.borderLight,
          width: _isActive ? 0.5 : 0.5,
        ),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onChangedSearch,
        onTap: () => setState(() => _isActive = true),
        onSubmitted: (_) => setState(() => _isActive = false),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: Translate.t("search.name"),
          hintStyle: TextStyle(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: _isActive ? AppColors.accent : AppColors.primary,
              size: 24,
            ),
          ),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    widget.searchController.clear();
                    widget.onChangedSearch("");
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class DateRangePicker extends StatelessWidget {
  String? date;
  Function()? onChangedDate;
  DateRangePicker({super.key, required this.date, required this.onChangedDate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChangedDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: Translate.t("filter.DateRange"),
          labelStyle: AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
            color: AppColors.primary,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(width: 1),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(date ?? Translate.t("filter.SelectDate")),
      ),
    );
  }
}

class FilterButtons extends StatefulWidget {
  String selected = 'All Listings';
  final ValueChanged<String> onFilterChanged;
  List<String>? filters = ['All Listings', 'RCN', 'Kernel'];
  final Function() onFilterToggle;
  FilterButtons({
    super.key,
    required this.onFilterToggle,
    required this.onFilterChanged,
    required this.selected,
    this.filters,
  });

  @override
  State<FilterButtons> createState() => _FilterButtonsState();
}

class _FilterButtonsState extends State<FilterButtons> {
  late List<String> filters;

  @override
  void initState() {
    super.initState();
    filters =
        widget.filters ??
        [
          Translate.t("filter.all_listings"),
          Translate.t("filter.rcn"),
          Translate.t("filter.kernel"),
        ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                filters.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    right: index < filters.length - 1 ? 10 : 0,
                  ),
                  child: FilterButton(
                    label: filters[index],

                    isSelected:
                        widget.selected ==
                        (filters[index] == Translate.t("filter.all_listings")
                            ? "All Listings"
                            : filters[index] == Translate.t("filter.rcn")
                            ? "RCN"
                            : "Kernel"),
                    onTap: () {
                      setState(() {
                        widget.selected =
                            filters[index] == Translate.t("filter.all_listings")
                            ? "All Listings"
                            : filters[index] == Translate.t("filter.rcn")
                            ? "RCN"
                            : "Kernel";
                        ;
                        widget.onFilterChanged(widget.selected);
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          isfilterbutton(onFilterToggle: widget.onFilterToggle),
        ],
      ),
    );
  }
}

class isfilterbutton extends StatelessWidget {
  final Function() onFilterToggle;
  const isfilterbutton({super.key, required this.onFilterToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFilterToggle,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: const Icon(
          Icons.filter_alt_outlined,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderLight,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Origin')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 16,
                ),
              ),
            Text(
              label,
              style: AppTextThemes.getLightTextTheme.bodySmall!.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
