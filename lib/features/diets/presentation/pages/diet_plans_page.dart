import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/diet_plans_cubit.dart';
import '../cubit/diet_plans_state.dart';
import '../widgets/add_diet_plan_dialog.dart';
import '../../domain/entities/diet_plan.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';

class DietPlansPage extends StatefulWidget {
  const DietPlansPage({super.key});

  @override
  State<DietPlansPage> createState() => _DietPlansPageState();
}

class _DietPlansPageState extends State<DietPlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<DietPlansCubit>().fetchDietPlans();
  }

  void _showAddEditDialog([DietPlan? dietPlan]) async {
    final result = await showDialog<DietPlan>(
      context: context,
      builder: (context) => AddDietPlanDialog(dietPlan: dietPlan),
    );

    if (result != null && mounted) {
      if (dietPlan == null) {
        context.read<DietPlansCubit>().addDietPlan(result);
      } else {
        context.read<DietPlansCubit>().updateDietPlan(result);
      }
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من حذف هذا النظام الغذائي؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DietPlansCubit>().deleteDietPlan(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DietPlansCubit, DietPlansState>(
      listener: (context, state) {
        if (state is DietPlanOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is DietPlansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SidebarLayout(
        activePage: 'diets',
        title: 'الأنظمة الغذائية',
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'قائمة الأنظمة الغذائية',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ColorPalette.primaryColor),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة نظام', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<DietPlansCubit, DietPlansState>(
                  builder: (context, state) {
                    if (state is DietPlansLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is DietPlansLoaded) {
                      if (state.dietPlans.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أنظمة غذائية مضافة',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.dietPlans.length,
                        itemBuilder: (context, index) {
                          final dietPlan = state.dietPlans[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dietPlan.name,
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorPalette.primaryColor),
                                            ),
                                            if (dietPlan.price > 0)
                                              Text(
                                                'السعر: ${dietPlan.price.toStringAsFixed(0)} ج.م',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showAddEditDialog(dietPlan),
                                            tooltip: 'تعديل',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmDelete(dietPlan.id!),
                                            tooltip: 'حذف',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (dietPlan.description != null && dietPlan.description!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(dietPlan.description!, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                  ],
                                  const SizedBox(height: 16),
                                  const Text('الوجبات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorPalette.secondaryColor)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: double.infinity,
                                    child: Text(
                                      dietPlan.meals,
                                      style: const TextStyle(fontSize: 16, height: 1.5),
                                    ),
                                  ),
                                  if (dietPlan.notes != null && dietPlan.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text('ملاحظات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 4),
                                    Text(dietPlan.notes!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is DietPlansError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
