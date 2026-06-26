import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddMember;
  final VoidCallback onAddPayment;
  final VoidCallback onInquireAndRenew;
  final VoidCallback onAttendance;
  final bool isDarkMode;

  const QuickActionsSection({
    super.key,
    required this.onAddMember,
    required this.onAddPayment,
    required this.onInquireAndRenew,
    required this.onAttendance,
    required this.isDarkMode,
  });

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildQuickActionBtn(
            icon: Icons.person_add_alt_1_rounded,
            label: 'عضو جديد',
            color: ColorPalette.primaryColor,
            onPressed: onAddMember,
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.add_card_rounded,
            label: 'إضافة دفعة',
            color: ColorPalette.successColor,
            onPressed: onAddPayment,
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.search_rounded,
            label: 'استعلام وتجديد اشتراك',
            color: ColorPalette.infoColor,
            onPressed: onInquireAndRenew,
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.check_circle_rounded,
            label: 'تسجيل حضور',
            color: 
                 ColorPalette.primaryColor,
               
            onPressed: onAttendance,
          ),
        ],
      ),
    );
  }
}
