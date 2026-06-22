import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/attendance_entity.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../../../members/domain/entities/member_entity.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  // لتعطيل المسح المتكرر لنفس العضو في فترة قصيرة
  String? _lastScannedBarcode;
  DateTime? _lastScannedTime;

  String _scanMode = 'تلقائي'; // تلقائي، دخول، خروج

  @override
  void initState() {
    super.initState();
    // تحميل البيانات عند فتح الصفحة
    context.read<AttendanceCubit>().loadDailyData();
    // تركيز تلقائي على حقل مسح الباركود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scanFocusNode.dispose();
    _scanCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScanSubmitted(String value) {
    final scannedValue = value.trim();
    if (scannedValue.isEmpty) return;

    final now = DateTime.now();
    if (_lastScannedBarcode == scannedValue &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!).inSeconds < 5) {
      _scanCtrl.clear();
      _scanFocusNode.requestFocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم مسح هذا الكود للتو، يرجى الانتظار قليلاً.', style: TextStyle(fontFamily: 'Cairo')),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _lastScannedBarcode = scannedValue;
    _lastScannedTime = now;

    context.read<AttendanceCubit>().processScan(scannedValue, _scanMode);
    _scanCtrl.clear();
    // إعادة التركيز بعد الإرسال
    _scanFocusNode.requestFocus();
  }

  void _onSearchChanged(String value) {
    context.read<AttendanceCubit>().search(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SidebarLayout(
      activePage: 'attendance',
      title: 'حضور وانصراف العملاء',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<AttendanceCubit>().loadDailyData();
            _scanFocusNode.requestFocus();
          },
          tooltip: 'تحديث البيانات',
        ),
      ],
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        state.type == 'حضور' ? Icons.login : Icons.logout,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: state.type == 'حضور'
                      ? ColorPalette.successColor
                      : ColorPalette.infoColor,
                  duration: const Duration(seconds: 3),
                ),
              );
              // إخلاء مربع البحث وإعادة تركيز الباركود
              _scanFocusNode.requestFocus();
            } else if (state is AttendanceError) {
              if (state.message.contains('منتهي') || state.message.contains('منتهية')) {
                AudioService.playAlertSound();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: ColorPalette.errorColor,
                  duration: const Duration(seconds: 4),
                ),
              );
              _scanFocusNode.requestFocus();
            }
          },
          builder: (context, state) {
            List<Attendance> dailyAttendance = [];
            Map<String, dynamic> stats = {
              'todayCount': 0,
              'averageDaily': 0.0,
              'topMembers': [],
            };
            List<Member> searchResults = [];
            bool isLoading = state is AttendanceLoading;

            if (state is AttendanceLoaded) {
              dailyAttendance = state.dailyAttendance;
              stats = state.stats;
              searchResults = state.searchResults;
            } else if (state is AttendanceActionSuccess) {
              // للحفاظ على البيانات المعروضة أثناء إظهار الرسالة
              // في حال كانت الحالة action نجلب البيانات السابقة
              // لكن بما أن الـ cubit يقوم تلقائياً بطلب تحديث البيانات بعد النجاح،
              // فستتحول الحالة سريعاً إلى Loaded.
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 950;
                  final content = [
                    // الجانب الأيمن / العلوي: شريط التحكم والبحث والمسح
                    SizedBox(
                      width: isWide ? 380 : double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScannerCard(theme, isDark),
                          const SizedBox(height: 16),
                          _buildSearchCard(theme, searchResults),
                        ],
                      ),
                    ),
                    if (isWide) const SizedBox(width: 24),
                    if (!isWide) const SizedBox(height: 24),
                    // الجانب الأيسر / السفلي: الإحصائيات وجدول الحضور اليومي
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        children: [
                          _buildStatsRow(theme, stats, isDark),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildAttendanceTable(theme, dailyAttendance, isLoading, isDark),
                          ),
                        ],
                      ),
                    ),
                  ];

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: content,
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              content[0], // Scanner & Search
                              const SizedBox(height: 24),
                              // في حال الشاشات الضيقة، نجعل ارتفاع جدول الحضور ثابتاً لكي يظهر بشكل جيد
                              SizedBox(
                                height: 500,
                                child: Column(
                                  children: [
                                    _buildStatsRow(theme, stats, isDark),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: _buildAttendanceTable(theme, dailyAttendance, isLoading, isDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            );
          },
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // كرت مسح الباركود
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildScannerCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner, color: ColorPalette.primaryColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  'مسح الرمز (QR / Barcode)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // حقل إدخال الباركود
            TextFormField(
              controller: _scanCtrl,
              focusNode: _scanFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: _onScanSubmitted,
              decoration: InputDecoration(
                labelText: 'امسح الرمز أو اكتب رقم العضوية',
                hintText: 'مثال: MEM-1718...',
                prefixIcon: const Icon(Icons.keyboard),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_left_outlined),
                  onPressed: () => _onScanSubmitted(_scanCtrl.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            // أزرار تحديد وضع المسح
            Text(
              'وضع تسجيل الحركة:',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildModeRadio('تلقائي'),
                const SizedBox(width: 8),
                _buildModeRadio('دخول'),
                const SizedBox(width: 8),
                _buildModeRadio('خروج'),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: ColorPalette.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scanMode == 'تلقائي'
                          ? 'الوضع التلقائي يقوم بتسجيل الدخول إذا كان العضو خارج الصالة، ويسجل خروجه إذا كان بالداخل.'
                          : _scanMode == 'دخول'
                              ? 'سيتم تسجيل "حضور ودخول" فقط لأي رمز يتم مسحه.'
                              : 'سيتم تسجيل "انصراف وخروج" فقط لأي رمز يتم مسحه.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeRadio(String mode) {
    final isSelected = _scanMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _scanMode = mode;
          });
          _scanFocusNode.requestFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ColorPalette.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? ColorPalette.primaryColor : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              mode,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // كرت البحث اليدوي والنتائج
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchCard(ThemeData theme, List<Member> searchResults) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: ColorPalette.primaryColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  'البحث والتسجيل اليدوي',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'ابحث بالاسم أو الهاتف أو الرمز',
                hintText: 'اكتب للبحث السريع...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              Text(
                'نتائج البحث (${searchResults.length}):',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'رقم الهاتف: ${member.phoneNumber ?? "لا يوجد"}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                                Text(
                                  'الرمز: ${member.memberId}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // أزرار الحضور والانصراف السريعة
                          IconButton(
                            icon: const Icon(Icons.login, color: ColorPalette.successColor),
                            tooltip: 'تسجيل دخول',
                            onPressed: () {
                              context.read<AttendanceCubit>().checkIn(member.memberId);
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: ColorPalette.infoColor),
                            tooltip: 'تسجيل خروج',
                            onPressed: () {
                              context.read<AttendanceCubit>().checkOut(member.memberId);
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else if (_searchCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'لا توجد نتائج مطابقة لبحثك',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط الإحصائيات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(ThemeData theme, Map<String, dynamic> stats, bool isDark) {
    final todayCount = stats['todayCount'] as int? ?? 0;
    final averageDaily = stats['averageDaily'] as double? ?? 0.0;
    final topMembers = stats['topMembers'] as List<dynamic>? ?? [];

    String topMemberStr = 'لا يوجد حضور كافٍ';
    if (topMembers.isNotEmpty) {
      final first = topMembers.first;
      topMemberStr = '${first['fullName']} (${first['count']} أيام)';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'حضور اليوم',
            todayCount.toString(),
            Icons.people,
            ColorPalette.primaryColor,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'متوسط الحضور اليومي',
            averageDaily.toStringAsFixed(1),
            Icons.bar_chart,
            ColorPalette.infoColor,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            'الأكثر حضوراً',
            topMemberStr,
            Icons.workspace_premium,
            ColorPalette.successColor,
            isDark,
            isTextLong: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    bool isTextLong = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? ColorPalette.textSecondaryDark : ColorPalette.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTextLong ? 12 : 18,
                      color: isDark ? ColorPalette.textPrimaryDark : ColorPalette.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جدول الحضور اليومي
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAttendanceTable(
    ThemeData theme,
    List<Attendance> list,
    bool isLoading,
    bool isDark,
  ) {
    if (isLoading && list.isEmpty) {
      return const Card(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (list.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_accounts_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'لم يتم تسجيل حضور أي عضو اليوم بعد',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'استخدم الباركود أو ابحث لتسجيل أول حركة دخول.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'سجل الحضور والانصراف لليوم',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? ColorPalette.tableHeaderDark : ColorPalette.tableHeaderLight.withOpacity(0.05),
                    ),
                    columns: const [
                      DataColumn(label: Text('اسم العضو', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('رقم العضوية', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('وقت الدخول', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('وقت الخروج', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('مدة التمرين', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: list.map((a) {
                      final inTime = DateTime.tryParse(a.checkInTime);
                      final outTime = a.checkOutTime != null ? DateTime.tryParse(a.checkOutTime!) : null;

                      final formattedIn = inTime != null ? DateFormat('hh:mm a').format(inTime) : '-';
                      final formattedOut = outTime != null ? DateFormat('hh:mm a').format(outTime) : '-';

                      return DataRow(
                        cells: [
                          DataCell(Text(
                            a.memberName ?? 'عضو غير معروف',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          DataCell(Text(a.memberId)),
                          DataCell(Text(formattedIn)),
                          DataCell(
                            a.checkOutTime == null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.successColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'داخل الصالة',
                                      style: TextStyle(
                                        color: ColorPalette.successColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                : Text(formattedOut),
                          ),
                          DataCell(Text(
                            a.durationMinutes != null ? '${a.durationMinutes} دقيقة' : '-',
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
           },
          ),
         ),
        ],
      ),
    );
  }
}
