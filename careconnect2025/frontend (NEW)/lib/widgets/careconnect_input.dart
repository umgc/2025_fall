import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/careconnect_theme.dart';

/// Enhanced CareConnect input field with modern styling
class CareConnectInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final CareConnectInputSize size;

  const CareConnectInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.size = CareConnectInputSize.medium,
  });

  @override
  State<CareConnectInput> createState() => _CareConnectInputState();
}

class _CareConnectInputState extends State<CareConnectInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: CareConnectTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? CareConnectTheme.darkTextPrimary : CareConnectTheme.textPrimary,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingS),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            textCapitalization: widget.textCapitalization,
            style: CareConnectTheme.bodyMedium.copyWith(
              color: isDark ? CareConnectTheme.darkTextPrimary : CareConnectTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              errorText: widget.errorText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffixIcon(),
              filled: true,
              fillColor: widget.enabled
                  ? (isDark ? CareConnectTheme.darkSurfaceColor : CareConnectTheme.surfaceColor)
                  : (isDark ? CareConnectTheme.darkSurfaceColor.withValues(alpha:0.5) : CareConnectTheme.surfaceColor.withValues(alpha:0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                borderSide: BorderSide(
                  color: hasError
                      ? CareConnectTheme.errorColor
                      : (isDark ? CareConnectTheme.darkBorderColor : CareConnectTheme.borderColor),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                borderSide: BorderSide(
                  color: hasError
                      ? CareConnectTheme.errorColor
                      : (isDark ? CareConnectTheme.darkBorderColor : CareConnectTheme.borderColor),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                borderSide: const BorderSide(
                  color: CareConnectTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                borderSide: const BorderSide(
                  color: CareConnectTheme.errorColor,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                borderSide: const BorderSide(
                  color: CareConnectTheme.errorColor,
                  width: 2,
                ),
              ),
              contentPadding: _getContentPadding(),
              hintStyle: CareConnectTheme.bodyMedium.copyWith(
                color: isDark ? CareConnectTheme.darkTextTertiary : CareConnectTheme.textTertiary,
              ),
              helperStyle: CareConnectTheme.bodySmall.copyWith(
                color: isDark ? CareConnectTheme.darkTextSecondary : CareConnectTheme.textSecondary,
              ),
              errorStyle: CareConnectTheme.bodySmall.copyWith(
                color: CareConnectTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: _isFocused
              ? CareConnectTheme.primaryColor
              : (Theme.of(context).brightness == Brightness.dark
                  ? CareConnectTheme.darkTextSecondary
                  : CareConnectTheme.textSecondary),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  EdgeInsetsGeometry _getContentPadding() {
    switch (widget.size) {
      case CareConnectInputSize.small:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingM,
          vertical: CareConnectTheme.spacingS,
        );
      case CareConnectInputSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingM,
          vertical: CareConnectTheme.spacingM,
        );
      case CareConnectInputSize.large:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingL,
          vertical: CareConnectTheme.spacingL,
        );
    }
  }
}

enum CareConnectInputSize {
  small,
  medium,
  large,
}

/// Specialized input for search functionality
class CareConnectSearchInput extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function()? onClear;
  final bool showClearButton;

  const CareConnectSearchInput({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CareConnectInput(
      controller: controller,
      hint: hint ?? 'Search...',
      onChanged: onChanged,
      prefixIcon: Icon(
        Icons.search,
        color: isDark ? CareConnectTheme.darkTextSecondary : CareConnectTheme.textSecondary,
      ),
      suffixIcon: showClearButton && (controller?.text.isNotEmpty ?? false)
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: isDark ? CareConnectTheme.darkTextSecondary : CareConnectTheme.textSecondary,
              ),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}
