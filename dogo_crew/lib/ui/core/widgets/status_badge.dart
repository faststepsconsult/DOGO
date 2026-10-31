import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    this.icon,
  });

  factory StatusBadge.service(String service) {
    final label = AppConstants.serviceLabels[service] ?? service;
    return StatusBadge(
      label: label,
      textColor: AppColors.gold,
      backgroundColor: AppColors.goldBg,
      borderColor: AppColors.goldBorder,
      icon: service == 'bike'
          ? Icons.two_wheeler_rounded
          : service == 'keke'
              ? Icons.electric_rickshaw_rounded
              : Icons.local_taxi_rounded,
    );
  }

  factory StatusBadge.tripStatus(String status) {
    final label = AppConstants.statusLabels[status] ?? status;
    Color text = AppColors.brandLight;
    Color bg = AppColors.brand.withAlpha(25);
    Color border = AppColors.brand.withAlpha(80);

    if (status == 'completed') {
      text = AppColors.success;
      bg = AppColors.successBg;
      border = AppColors.successBorder;
    } else if (status == 'cancelled') {
      text = AppColors.destructive;
      bg = AppColors.destructiveBg;
      border = AppColors.destructiveBorder;
    } else if (status == 'pending') {
      text = AppColors.gold;
      bg = AppColors.goldBg;
      border = AppColors.goldBorder;
    }

    return StatusBadge(
      label: label,
      textColor: text,
      backgroundColor: bg,
      borderColor: border,
    );
  }

  factory StatusBadge.payment(String paymentStatus) {
    final label = AppConstants.paymentLabels[paymentStatus] ?? paymentStatus;
    final isPaid = paymentStatus == 'paid';
    return StatusBadge(
      label: label,
      textColor: isPaid ? AppColors.success : AppColors.gold,
      backgroundColor: isPaid ? AppColors.successBg : AppColors.goldBg,
      borderColor: isPaid ? AppColors.successBorder : AppColors.goldBorder,
    );
  }

  factory StatusBadge.verification(String status) {
    final label = AppConstants.verifyLabels[status] ?? status;
    Color text = AppColors.gold;
    Color bg = AppColors.goldBg;
    Color border = AppColors.goldBorder;

    if (status == 'approved') {
      text = AppColors.success;
      bg = AppColors.successBg;
      border = AppColors.successBorder;
    } else if (status == 'rejected') {
      text = AppColors.destructive;
      bg = AppColors.destructiveBg;
      border = AppColors.destructiveBorder;
    }

    return StatusBadge(
      label: label,
      textColor: text,
      backgroundColor: bg,
      borderColor: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
