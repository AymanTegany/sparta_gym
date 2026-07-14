import 'package:flutter/material.dart';
import 'package:updat/updat.dart';
import '../../theme/color_palette.dart';

Widget buildArabicUpdateChip({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  String text = '';
  IconData icon = Icons.system_update;
  Color bgColor = Colors.orange;
  void Function()? onTap;

  switch (status) {
    case UpdatStatus.available:
    case UpdatStatus.availableWithChangelog:
      text = 'تحديث متوفر ($latestVersion)';
      icon = Icons.download_rounded;
      bgColor = Colors.orange;
      onTap = startUpdate;
      break;
    case UpdatStatus.checking:
      text = 'جاري التحقق...';
      icon = Icons.hourglass_empty;
      bgColor = Colors.grey;
      break;
    case UpdatStatus.upToDate:
      text = 'التطبيق محدث';
      icon = Icons.check_circle;
      bgColor = ColorPalette.successColor;
      break;
    case UpdatStatus.error:
      text = 'خطأ في التحديث';
      icon = Icons.error;
      bgColor = ColorPalette.errorColor;
      break;
    case UpdatStatus.idle:
      text = 'التحقق من التحديثات';
      icon = Icons.refresh;
      bgColor = Colors.blue;
      onTap = checkForUpdate;
      break;
    case UpdatStatus.downloading:
      text = 'جاري التحميل...';
      icon = Icons.downloading;
      bgColor = Colors.blueAccent;
      break;
    case UpdatStatus.readyToInstall:
      text = 'جاهز للتثبيت (اضغط هنا)';
      icon = Icons.install_desktop;
      bgColor = ColorPalette.successColor;
      onTap = () => launchInstaller();
      break;
    case UpdatStatus.dismissed:
      return const SizedBox.shrink();
  }

  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white),
    label: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
