import 'dart:core';

bool isShiftActivePeriod(int currentMins, int startMins, int endMins) {
  if (startMins < endMins) {
    return currentMins >= startMins && currentMins < endMins;
  } else if (startMins > endMins) {
    return currentMins >= startMins || currentMins < endMins;
  } else {
    return true; // 24 ساعة
  }
}

void main() {
  final now = DateTime.now();
  final currentMins = now.hour * 60 + now.minute;
  
  print('Now: ${now.hour}:${now.minute}, Mins: $currentMins');
  
  // Test start 12:09 AM, end 11:59 PM
  final startMins = 0 * 60 + 9;
  final endMins = 23 * 60 + 59;
  
  print('Start Mins: $startMins');
  print('End Mins: $endMins');
  
  final active = isShiftActivePeriod(currentMins, startMins, endMins);
  print('Is Active: $active');
}
