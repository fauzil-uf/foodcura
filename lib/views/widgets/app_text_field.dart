import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

/// TextField & TextFormField terpusat dengan icon kiri, opsional toggle password,
/// dan dukungan validator FormState sesuai standar kurikulum Validasi Form.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final Color fillColor;
  final double radius;
  final double height;
  final TextStyle? textStyle;
  final bool bordered;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.fillColor = AppColors.inputFill,
    this.radius = 16,
    this.height = 56,
    this.textStyle,
    this.bordered = false,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  /// Membangun bidang input teks dengan ikon di kiri, border membulat, dan tombol toggle visibilitas sandi opsional.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(widget.radius),
            border: widget.bordered
                ? Border.all(color: AppColors.border)
                : Border.all(color: AppColors.borderSoft, width: 1),
            boxShadow: widget.bordered
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            style: widget.textStyle ?? AppTextStyles.inputText,
            validator: widget.validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: (widget.textStyle ?? AppTextStyles.inputText).copyWith(
                color: AppColors.textGray.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
