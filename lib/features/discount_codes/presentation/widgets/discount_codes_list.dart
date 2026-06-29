import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/discount_code.dart';
import '../cubit/discount_codes_cubit.dart';
import '../cubit/discount_codes_state.dart';
import 'add_discount_code_dialog.dart';

class DiscountCodesList extends StatefulWidget {
  const DiscountCodesList({super.key});

  @override
  State<DiscountCodesList> createState() => _DiscountCodesListState();
}

class _DiscountCodesListState extends State<DiscountCodesList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountCodesCubit>().loadDiscountCodes();
    });
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddDiscountCodeDialog(
        onSave: (newCode) {
          context.read<DiscountCodesCubit>().addDiscountCode(newCode);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, DiscountCode code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddDiscountCodeDialog(
        discountCode: code,
        onSave: (updatedCode) {
          context.read<DiscountCodesCubit>().updateDiscountCode(updatedCode);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DiscountCode code) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('حذف كود الخصم', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف كود الخصم "${code.name}"؟',
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
                context.read<DiscountCodesCubit>().deleteDiscountCode(code.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف الكود'),
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

  String _formatValue(DiscountCode code) {
    if (code.type == 'percentage') {
      return '${code.value.toStringAsFixed(0)}%';
    }
    return '${code.value.toStringAsFixed(0)} ج.م';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أكواد الخصم',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة كود خصم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<DiscountCodesCubit, DiscountCodesState>(
            listener: (context, state) {
              if (state is DiscountCodeActionSuccess) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: ColorPalette.activeStatus,
                    ),
                  );
              }
              if (state is DiscountCodesError) {
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
              if (state is DiscountCodesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DiscountCodesLoaded) {
                final codes = state.discountCodes;

                if (codes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.discount_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('لا توجد أكواد خصم معرفة حالياً'),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 64,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              theme.brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('اسم الكود', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نوع الخصم', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('القيمة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('تاريخ الإنشاء', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: codes.map((code) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(code.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(code.type == 'percentage' ? 'نسبة مئوية' : 'مبلغ ثابت')),
                                  DataCell(Text(_formatValue(code))),
                                  DataCell(Text(_formatDate(code.createdAt))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                          tooltip: 'تعديل',
                                          onPressed: () => _showEditDialog(context, code),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                          tooltip: 'حذف',
                                          onPressed: () => _showDeleteConfirmDialog(context, code),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
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
                );
              }

              return const Center(child: Text('تحميل البيانات...'));
            },
          ),
        ),
      ],
    );
  }
}
