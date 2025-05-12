import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_panel/config/theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final bool readOnly;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final double elevation;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.initialValue,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          elevation: elevation,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            validator: validator,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            minLines: minLines,
            enabled: enabled,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onEditingComplete: onEditingComplete,
            onFieldSubmitted: onFieldSubmitted,
            autofocus: autofocus,
            readOnly: readOnly,
            style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
            cursorColor: AppTheme.accentColor,
            cursorWidth: 1.5,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              prefixIcon:
                  prefixIcon != null
                      ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: prefixIcon,
                      )
                      : null,
              suffixIcon:
                  suffixIcon != null
                      ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: suffixIcon,
                      )
                      : null,
              contentPadding:
                  contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              filled: filled,
              fillColor:
                  enabled
                      ? (fillColor ?? AppTheme.surfaceColor)
                      : Colors.grey[100],
              hintStyle: TextStyle(
                color: AppTheme.textLightColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              helperStyle: TextStyle(
                color: AppTheme.textLightColor.withOpacity(0.7),
                fontSize: 12,
              ),
              errorStyle: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accentColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;

  const PasswordTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.initialValue,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      initialValue: widget.initialValue,
      contentPadding: widget.contentPadding,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.secondaryColor,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
