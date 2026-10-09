import 'package:flutter/material.dart';

/// ChatFlow 设计 Token —— UI 中所有颜色必须引用此处，禁止硬编码色值。
/// 与 docs/design.html 的视觉风格保持一致。
class DesignTokens {
  // 品牌色
  static const Color primary = Color(0xFF6366F1); // 靛蓝主色
  static const Color accent = Color(0xFF8B5CF6); // 渐变紫
  static const Color streaming = Color(0xFF22C55E); // 流式绿

  // 浅色主题
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // 深色主题
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // 文字
  static const Color inkDark = Color(0xFF0F172A);
  static const Color inkLight = Color(0xFFF1F5F9);
  static const Color subText = Color(0xFF64748B);

  // 气泡
  static const Color userBubble = primary; // 用户气泡
  static const Color aiBubbleLight = lightSurface; // AI 气泡（浅色）
  static const Color aiBubbleDark = Color(0xFF1E293B);

  // 圆角
  static const double radiusSmall = 4.0;
  static const double radiusChip = 12.0;
  static const double radius = 14.0;
  static const double radiusInput = 18.0;

  // 字号
  static const double fontSizeCaption = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeTitle = 16.0;

  // 间距
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
}
