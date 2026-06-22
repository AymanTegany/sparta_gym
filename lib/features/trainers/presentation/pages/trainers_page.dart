import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/common/widgets/sidebar_layout.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/trainer_entity.dart';
import '../cubit/trainers_cubit.dart';
import '../cubit/trainers_state.dart';
import '../widgets/add_trainer_dialog.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// شاشة إدارة المدربين (Trainers Page)
/// ──────────────────────────────────────────────────────────────────────────────
class TrainersPage extends StatefulWidget {
  const TrainersPage({super.key});

  @override
  State<TrainersPage> createState() => _TrainersPageState();
}

class _TrainersPageState extends State<TrainersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainersCubit>().loadTrainers();
    });
  }

  void _showAddTrainerDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddTrainerDialog(
        onSave: (newTrainer) {
          context.read<TrainersCubit>().addTrainer(newTrainer);
        },
      ),
    );
  }

  void _showEditTrainerDialog(BuildContext context, Trainer trainer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddTrainerDialog(
        trainer: trainer,
        onSave: (updatedTrainer) {
          context.read<TrainersCubit>().updateTrainer(updatedTrainer);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Trainer trainer) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('حذف المدرب', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف المدرب "${trainer.fullName}"؟\nسيتم حذف بيانات المدرب نهائياً.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<TrainersCubit>().deleteTrainer(trainer.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف المدرب'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SidebarLayout(
      activePage: 'trainers',
      title: 'إدارة المدربين',
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTrainerDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مدرب جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث البيانات',
          onPressed: () => context.read<TrainersCubit>().loadTrainers(),
        ),
      ],
      body: BlocConsumer<TrainersCubit, TrainersState>(
          listener: (context, state) {
            if (state is TrainerActionSuccess) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ColorPalette.activeStatus,
                  ),
                );
            }
            if (state is TrainersError) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is TrainersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TrainersLoaded) {
              final trainers = state.trainers;

              if (trainers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_gymnastics_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('لا يوجد مدربين مسجلين حالياً', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTrainerDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مدرب أول'),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // إحصائيات سريعة
                    _buildStatsRow(trainers, theme),
                    const SizedBox(height: 24),

                    // جدول المدربين
                    Expanded(
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width - 380,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  theme.brightness == Brightness.dark
                                      ? Colors.grey[850]
                                      : Colors.grey[200],
                                ),
                                columns: const [
                                  DataColumn(label: Text('اسم المدرب', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('التخصص', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الراتب', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ساعات العمل', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('تاريخ الإضافة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: trainers.map((trainer) {
                                  return DataRow(
                                    cells: [
                                      // اسم المدرب
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: primary.withValues(alpha: 0.15),
                                              child: Text(
                                                trainer.fullName.substring(0, 1).toUpperCase(),
                                                style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(trainer.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      // رقم الهاتف
                                      DataCell(Text(trainer.phoneNumber)),
                                      // التخصص
                                      DataCell(Text(trainer.specialization ?? '—')),
                                      // الراتب
                                      DataCell(Text(
                                        trainer.salary != null
                                            ? '${_formatCurrency(trainer.salary!)} ج.م'
                                            : '—',
                                      )),
                                      // ساعات العمل
                                      DataCell(Text(trainer.workingHours ?? '—')),
                                      // الحالة
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: trainer.isActive
                                                ? ColorPalette.activeStatus.withValues(alpha: 0.12)
                                                : ColorPalette.expiredStatus.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            trainer.isActive ? 'نشط' : 'غير نشط',
                                            style: TextStyle(
                                              color: trainer.isActive
                                                  ? ColorPalette.activeStatus
                                                  : ColorPalette.expiredStatus,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // تاريخ الإضافة
                                      DataCell(Text(_formatDate(trainer.createdAt))),
                                      // الإجراءات
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                              tooltip: 'تعديل المدرب',
                                              onPressed: () => _showEditTrainerDialog(context, trainer),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                              tooltip: 'حذف المدرب',
                                              onPressed: () => _showDeleteConfirmDialog(context, trainer),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('تحميل البيانات...'));
          },
        ),
      );
  }

  /// شريط إحصائيات سريعة
  Widget _buildStatsRow(List<Trainer> trainers, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final activeCount = trainers.where((t) => t.isActive).length;
    final inactiveCount = trainers.length - activeCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'إجمالي المدربين',
            '${trainers.length}',
            Icons.group_rounded,
            ColorPalette.primaryColor,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'المدربين النشطين',
            '$activeCount',
            Icons.check_circle_rounded,
            ColorPalette.successColor,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'المدربين غير النشطين',
            '$inactiveCount',
            Icons.cancel_rounded,
            ColorPalette.errorColor,
            isDark,
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
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: isDark ? ColorPalette.textPrimaryDark : ColorPalette.textPrimaryLight,
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
}
