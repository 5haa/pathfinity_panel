import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';

enum ButtonType { primary, secondary, success, danger, warning, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height = 52.0,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child:
          type == ButtonType.outline
              ? _buildOutlinedButton()
              : _buildElevatedButton(),
    );
  }

  Widget _buildElevatedButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getButtonColor(),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        side: BorderSide(color: _getButtonColor(), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      ),
      child: _buildButtonContent(isOutlined: true),
    );
  }

  Widget _buildButtonContent({bool isOutlined = false}) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: isOutlined ? AppTheme.accentColor : Colors.white,
          strokeWidth: 2.0,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isOutlined ? _getButtonColor() : Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isOutlined ? _getButtonColor() : Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: isOutlined ? _getButtonColor() : Colors.white,
      ),
    );
  }

  Color _getButtonColor() {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.accentColor;
      case ButtonType.secondary:
        return AppTheme.secondaryColor;
      case ButtonType.success:
        return AppTheme.successColor;
      case ButtonType.danger:
        return AppTheme.errorColor;
      case ButtonType.warning:
        return AppTheme.warningColor;
      case ButtonType.outline:
        return AppTheme.accentColor;
    }
  }
}
