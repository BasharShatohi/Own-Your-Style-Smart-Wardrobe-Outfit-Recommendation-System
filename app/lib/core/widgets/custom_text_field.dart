import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_style.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final ValueNotifier<bool>? obscureTextNotifier; 

  const CustomTextField({
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureTextNotifier,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: obscureTextNotifier ?? ValueNotifier<bool>(false),
      builder: (context, isObscured, child) {
        return TextField(
          controller: controller,
          obscureText: obscureText ? isObscured : false,
          style: const TextStyle(color: AppColors.textDark), 
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 16), 
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(color: AppColors.textDark),
                    child: prefixIcon!,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: IconTheme(
                      data: const IconThemeData(color: AppColors.textDark),
                      child: suffixIcon!,
                    ),
                    onPressed: onSuffixIconPressed,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  )
                : obscureText
                    ? IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textDark,
                        ),
                        onPressed: onSuffixIconPressed ??
                            () {
                              obscureTextNotifier?.value = !isObscured;
                            },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      )
                    : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        );
      },
    );
  }
}