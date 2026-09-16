import 'package:flutter/material.dart';

/// Color palette for the CryptoMarket app.
/// Adapted from the web frontend's dark theme with mobile-friendly adjustments.
class AppColors {
  AppColors._();

  // ── Core Brand ─────────────────────────────────────────
  static const Color voltGreen = Color(0xFFDFFF00);
  static const Color voltGreenDim = Color(0x30DFFF00);

  // ── Backgrounds ────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFF0A0A0A);
  static const Color surfaceBg = Color(0xFF111111);
  static const Color deepBg = Color(0xFF161616);
  static const Color cardBg = Color(0xFF1A1A1A);
  static const Color hoverBg = Color(0xFF1E1E1E);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF4B5563);

  // ── Borders ────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF232E40);
  static const Color borderMuted = Color(0xFF374151);

  // ── Status ─────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color errorDim = Color(0x20F87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  // ── Trading ────────────────────────────────────────────
  static const Color priceUp = voltGreen;
  static const Color priceDown = Color(0xFF637381);
  static const Color buyColor = voltGreen;
  static const Color sellColor = error;
}
