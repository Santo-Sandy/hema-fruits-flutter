import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isRequired;
  final EdgeInsets? padding;
  final TextAlign textAlign;
  final int maxLines;

  const CustomLabel(
    this.text, {
    Key? key,
    this.style,
    this.isRequired = false,
    this.padding,
    this.maxLines = 1,
    this.textAlign = TextAlign.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          style: style ?? AppTextThemes.getLightTextTheme.titleSmall,
        ),
        if (isRequired)
          Text(
            ' *',
            style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}

/// Custom text form field with consistent styling and theme support
class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final TextInputType keyboardType;
  final int maxLines;
  final double height;
  final int minLines;
  final bool readonly;
  final bool suffixIconverification;
  final bool verified;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? suffixIcon;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final EdgeInsets contentPadding;
  final InputDecoration? decoration;
  final double borderRadius;
  final Function()? onTap;
  final Function()? onVerifyPressed;
  final String? errorText;
  final bool obscureText;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    this.label,
    this.decoration,
    this.onTap,
    this.readonly = false,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.inputFormatters,
    this.suffixIconverification = false,
    this.verified = false,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.height = 70,
    this.labelStyle,
    this.hintStyle,
    this.errorText,
    this.onVerifyPressed,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    this.borderRadius = 12,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        readOnly: readonly,
        obscureText: obscureText,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: AppTextThemes.getLightTextTheme.bodyLarge,
        decoration: InputDecoration(
          fillColor: Colors.white,
          labelText: label,
          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) {
              return AppTextThemes.getLightTextTheme.labelLarge!.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              );
            }

            return AppTextThemes.getLightTextTheme.labelLarge!.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            );
          }),
          floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) {
              return AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              );
            }

            return AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            );
          }),
          errorStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
            height: 1.2,
            color: AppColors.error,
          ),

          // helperText: ' ',
          // helperStyle: const TextStyle(fontSize: 8, height: 1.0),
          hintText: hintText,
          hintStyle:
              hintStyle ??
              AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                color: errorText != null ? AppColors.error : AppColors.textHint,
              ),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: contentPadding,
          suffixIcon: suffixIconverification
              ? verified
                    ? InkWell(
                        onTap: onVerifyPressed,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: onVerifyPressed,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.error,
                          ),
                        ),
                      )
              : suffixIcon != null
              ? InkWell(
                  onTap: onVerifyPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(suffixIcon, color: AppColors.primary),
                  ),
                )
              : null,
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }
}

class CustomTextFormFieldright extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final TextInputType keyboardType;
  final int maxLines;
  final double height;
  final int minLines;
  final bool readonly;
  final bool suffixIconverification;
  final bool verified;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final EdgeInsets contentPadding;
  final double borderRadius;
  final Function()? onTap;
  final Function()? onVerifyPressed;
  final Function()? onprefixPressed;
  final String? errorText;
  final bool obscureText;

  const CustomTextFormFieldright({
    Key? key,
    required this.controller,
    this.label,
    this.onTap,
    this.readonly = false,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.inputFormatters,
    this.suffixIconverification = false,
    this.verified = false,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.height = 70,
    this.labelStyle,
    this.hintStyle,
    this.errorText,
    this.onVerifyPressed,
    this.onprefixPressed,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    this.borderRadius = 12,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: TextFormField(
        readOnly: readonly,
        obscureText: obscureText,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: AppTextThemes.getLightTextTheme.bodyLarge,
        decoration: InputDecoration(
          fillColor: Colors.white,
          labelText: label,
          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) {
              return AppTextThemes.getLightTextTheme.labelLarge!.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              );
            }

            return AppTextThemes.getLightTextTheme.labelLarge!.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            );
          }),
          floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) {
              return AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              );
            }

            return AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            );
          }),
          errorStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
            height: 1.2,
            color: AppColors.error,
          ),

          // helperText: ' ',
          // helperStyle: const TextStyle(fontSize: 8, height: 1.0),
          hintText: hintText,
          hintStyle:
              hintStyle ??
              AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                color: errorText != null ? AppColors.error : AppColors.textHint,
              ),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: contentPadding,
          prefixIcon: prefixIcon == null
              ? null
              : InkWell(
                  onTap: onprefixPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: prefixIcon,
                  ),
                ),
          suffixIcon: InkWell(
            onTap: onVerifyPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: suffixIcon,
            ),
          ),
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }
}

class CustomDropdownFormField<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final List<String> labels;
  final String? label;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final IconData? icon;
  final double borderRadius;
  final bool enableAnimation;
  final Duration animationDuration;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final EdgeInsets contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? backgroundColor;
  final bool isEnabled;
  final bool isRequired;
  final double dropdownMaxHeight;
  final bool searchable;
  final InputDecoration? decoration;
  final String? searchHint;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.labels,
    this.label,
    this.hint,
    required this.onChanged,
    this.validator,
    this.icon,
    this.decoration,
    this.borderRadius = 12,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.prefixIcon,
    this.prefixIconColor,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 14,
    ),
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.backgroundColor,
    this.isEnabled = true,
    this.isRequired = false,
    this.dropdownMaxHeight = 300,
    this.searchable = false,
    this.searchHint = 'Search...',
  }) : assert(items.length == labels.length);

  @override
  State<CustomDropdownFormField<T>> createState() =>
      _CustomDropdownFormFieldState<T>();
}

class _CustomDropdownFormFieldState<T> extends State<CustomDropdownFormField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  bool _isOpen = false;
  bool get _isMounted => mounted;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredIndices = [];

  void _resetSearch() {
    _searchController.clear();
    _filteredIndices = List.generate(widget.items.length, (i) => i);
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase();
    _filteredIndices = widget.labels
        .asMap()
        .entries
        .where((e) => e.value.toLowerCase().contains(q))
        .map((e) => e.key)
        .toList();
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void initState() {
    super.initState();
    _filteredIndices = List.generate(widget.items.length, (i) => i);
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _toggleDropdown() {
    _isOpen ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    if (!_isMounted) return;
    FocusScope.of(context).unfocus();
    _resetSearch();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = _createOverlay();
    try {
      overlay.insert(_overlayEntry!);
      _animationController.forward();
      _isOpen = true;
    } catch (_) {}
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (_) {}
      _overlayEntry = null;
    }
    if (_animationController.isAnimating || _animationController.isCompleted) {
      try {
        _animationController.reverse();
      } catch (_) {}
    }
    _isOpen = false;
  }

  OverlayEntry _createOverlay() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      return OverlayEntry(builder: (_) => const SizedBox());
    }
    final size = renderObject.size;

    return OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: Offset(0, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: _buildDropdownList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownList() {
    return StatefulBuilder(
      builder: (_, setDropState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: widget.searchable
                ? widget.dropdownMaxHeight + 52
                : widget.dropdownMaxHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (q) {
                      setDropState(() => _onSearchChanged(q));
                    },
                    style: AppTextThemes.getLightTextTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: AppTextThemes.getLightTextTheme.bodyMedium
                          ?.copyWith(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: _filteredIndices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No results',
                            style: AppTextThemes.getLightTextTheme.bodyMedium
                                ?.copyWith(color: AppColors.textHint),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: _filteredIndices.length,
                        itemBuilder: (context, i) {
                          final idx = _filteredIndices[i];
                          final value = widget.items[idx];
                          final label = widget.labels[idx];
                          final isSelected = value == widget.value;

                          return InkWell(
                            onTap: () {
                              if (!_isMounted) return;
                              widget.onChanged?.call(value);
                              _closeDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: AppTextThemes
                                          .getLightTextTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.items.indexWhere((e) => e == widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        child: GestureDetector(
          onTap: widget.isEnabled ? _toggleDropdown : null,
          child: InputDecorator(
            decoration: widget.decoration != null
                ? widget.decoration!
                : InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    label: widget.label != null ? Text(widget.label!) : null,
                    labelStyle:
                        widget.labelStyle ??
                        WidgetStateTextStyle.resolveWith((states) {
                          if (states.contains(WidgetState.error)) {
                            return AppTextThemes.getLightTextTheme.labelLarge!
                                .copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                );
                          }

                          return AppTextThemes.getLightTextTheme.labelLarge!
                              .copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              );
                        }),
                    floatingLabelStyle: WidgetStateTextStyle.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.error)) {
                        return AppTextThemes.getLightTextTheme.titleMedium!
                            .copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            );
                      }

                      return AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      );
                    }),
                    hintText: widget.hint,
                    hintStyle:
                        widget.hintStyle ??
                        AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                          color: AppColors.textHint,
                        ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: widget.prefixIconColor ?? AppColors.primary,
                          )
                        : null,
                    suffixIcon: RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        widget.icon ?? Icons.arrow_drop_down,
                        color: widget.isEnabled
                            ? AppColors.primary
                            : AppColors.disabled,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: widget.borderColor ?? AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: widget.borderColor ?? AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: widget.focusedBorderColor ?? AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: widget.errorBorderColor ?? AppColors.error,
                      ),
                    ),
                  ),
            child: Text(
              selectedIndex >= 0
                  ? widget.labels[selectedIndex]
                  : (widget.hint ?? ''),
              style:
                  widget.textStyle ??
                  AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;
  final TextStyle? labelStyle;
  final EdgeInsets padding;
  final double borderRadius;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.labelStyle,
    this.padding = const EdgeInsets.all(0),
    this.borderRadius = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _activeColor = activeColor ?? AppColors.primary;
    final _inactiveColor = inactiveColor ?? Colors.transparent;
    final _borderColor = borderColor ?? AppColors.borderLight;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox square
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: value ? _activeColor : _inactiveColor,
                border: Border.all(
                  color: value ? _activeColor : _borderColor,
                  width: value ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: value
                  ? Center(
                      child: Icon(
                        Icons.check,
                        size: size * 0.6,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Label
            Flexible(
              child: Text(
                label,
                style:
                    labelStyle ??
                    AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                      color: value
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRadioButton<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String label;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;
  final TextStyle? labelStyle;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;

  const CustomRadioButton({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.labelStyle,
    this.padding = const EdgeInsets.all(0),
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final _activeColor = activeColor ?? AppColors.primary;
    final _inactiveColor = inactiveColor ?? Colors.transparent;
    final _borderColor = borderColor ?? AppColors.borderLight;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _activeColor : _inactiveColor,
                border: Border.all(
                  color: isSelected ? _activeColor : _borderColor,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: size * 0.4,
                        height: size * 0.4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 5),
            // Label
            Flexible(
              child: Text(
                label,
                style:
                    labelStyle ??
                    AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRadioGroup<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final List<String> labels;
  final ValueChanged<T?> onChanged;
  final Axis direction;
  final double spacing;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;
  final TextStyle? labelStyle;
  final double radioSize;
  final bool isrow;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isRequired;

  /// items and labels must have the same length
  const CustomRadioGroup({
    Key? key,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
    this.direction = Axis.horizontal,
    this.spacing = 10,
    this.activeColor,
    this.isrow = false,
    this.inactiveColor,
    this.borderColor,
    this.labelStyle,
    this.radioSize = 20,
    this.padding = const EdgeInsets.all(0),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.isRequired = false,
  }) : assert(
         items.length == labels.length,
         'items and labels must have the same length',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: direction == Axis.horizontal
          ? _buildHorizontal()
          : _buildVertical(),
    );
  }

  Widget _buildHorizontal() {
    return isrow
        ? Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: List.generate(items.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < items.length - 1 ? spacing : 0,
                ),
                child: CustomRadioButton<T>(
                  value: items[index],
                  groupValue: value,
                  onChanged: onChanged,
                  label: labels[index],
                  size: radioSize,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  borderColor: borderColor,
                  labelStyle: labelStyle,
                ),
              );
            }),
          )
        : Wrap(
            spacing: spacing,
            runSpacing: spacing / 2,
            alignment: WrapAlignment.values[mainAxisAlignment.index],
            crossAxisAlignment: WrapCrossAlignment.center,
            children: List.generate(items.length, (index) {
              return CustomRadioButton<T>(
                value: items[index],
                groupValue: value,
                onChanged: onChanged,
                label: labels[index],
                size: radioSize,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                borderColor: borderColor,
                labelStyle: labelStyle,
              );
            }),
          );
  }

  Widget _buildVertical() {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: List.generate(items.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < items.length - 1 ? spacing : 0,
          ),
          child: CustomRadioButton<T>(
            value: items[index],
            groupValue: value,
            onChanged: onChanged,
            label: labels[index],
            size: radioSize,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            borderColor: borderColor,
            labelStyle: labelStyle,
          ),
        );
      }),
    );
  }
}

/// Custom form header widget displaying title and subtitle
class FormHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;

  const FormHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.padding = const EdgeInsets.only(bottom: 24),
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Text(
            title,
            style: titleStyle ?? AppTextThemes.getLightTextTheme.headlineMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: subtitleStyle ?? AppTextThemes.getLightTextTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom progress indicator widget for multi-step forms
class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final double barWidth;
  final double barHeight;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final double borderRadius;

  const StepProgressIndicator({
    Key? key,
    required this.totalSteps,
    required this.currentStep,
    this.barWidth = 40,
    this.barHeight = 4,
    this.spacing = 8,
    required this.activeColor,
    required this.inactiveColor,
    this.borderRadius = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Row(
          children: [
            Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            if (index < totalSteps - 1) SizedBox(width: spacing),
          ],
        );
      }),
    );
  }
}

/// Custom submit button widget for forms
class CustomSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final Color? enabledColor;
  final Color? disabledColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final Widget? loadingWidget;

  const CustomSubmitButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
    this.enabledColor,
    this.disabledColor,
    this.borderRadius = 28,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? (enabledColor ?? AppColors.accent)
              : (disabledColor ?? AppColors.disabled),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          disabledBackgroundColor: disabledColor ?? AppColors.disabled,
          padding: padding,
        ),
        child: isLoading
            ? (loadingWidget ??
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ))
            : Text(
                label,
                style:
                    textStyle ??
                    AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
      ),
    );
  }
}
