import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tất cả TextStyle dùng Roboto (đã nhúng) để fix triệt để lỗi phông chữ tiếng Việt
class AppTextStyles {
  static const _font = 'Roboto';

  static TextStyle get h1 => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontFamily: _font,
  );

  static TextStyle get h2 => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFamily: _font,
  );

  static TextStyle get h3 => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: _font,
  );

  static TextStyle get h4 => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: _font,
  );

  static TextStyle get body => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: _font,
  );

  static TextStyle get bodyBold => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: _font,
  );

  static TextStyle get caption => TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: _font,
  );

  static TextStyle get hint =>
      TextStyle(color: AppColors.textHint, fontSize: 12, fontFamily: _font);

  static TextStyle get button => TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    fontFamily: _font,
  );

  static TextStyle get label => TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: _font,
  );

  // Colored variants
  static TextStyle primary(double size, FontWeight w) =>
      TextStyle(
        color: AppColors.primary,
        fontSize: size,
        fontWeight: w,
        fontFamily: _font,
      );

  static TextStyle colored(Color color, double size, FontWeight w) =>
      TextStyle(color: color, fontSize: size, fontWeight: w, fontFamily: _font);

  static TextStyle white(double size, FontWeight w) => TextStyle(
    color: Colors.white,
    fontSize: size,
    fontWeight: w,
    fontFamily: _font,
  );
}
