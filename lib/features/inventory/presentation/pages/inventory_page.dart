import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';
import '../../domain/entities/inventory_item_entity.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryCubit>().loadInventory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SidebarLayout(
      activePage: 'inventory',
      title: 'إدارة المخزون',
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
                color: theme.cardColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: 'المكملات الغذائية', icon: Icon(Icons.fitness_center_outlined)),
                    Tab(text: 'المشروبات', icon: Icon(Icons.local_drink_outlined)),
                    Tab(text: 'الأدوات الرياضية', icon: Icon(Icons.sports_gymnastics_outlined)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInventorySection('المكملات الغذائية', Icons.fitness_center_outlined, state),
                    _buildInventorySection('المشروبات', Icons.local_drink_outlined, state),
                    _buildInventorySection('الأدوات الرياضية', Icons.sports_gymnastics_outlined, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInventorySection(String category, IconData icon, InventoryState state) {
    List<InventoryItem> categoryItems = [];
    if (state is InventoryLoaded) {
      categoryItems = state.items.where((e) => e.category == category).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الأصناف: ${categoryItems.length}', 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () => _showAddInventoryItemDialog(context, category),
                icon: const Icon(Icons.add),
                label: Text('إضافة منتج'),
              )
            ],
          ),
        ),
        Expanded(
          child: categoryItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد عناصر حالية في $category',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: categoryItems.length,
                  itemBuilder: (context, index) {
                    final item = categoryItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكمية: ${item.quantity} ${item.barcode != null && item.barcode!.isNotEmpty ? '| باركود: ${item.barcode}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${item.price} ج.م', 
                                 style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<InventoryCubit>().deleteInventoryItem(item.id!);
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddInventoryItemDialog(BuildContext context, String defaultCategory) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final quantityController = TextEditingController();
    final barcodeController = TextEditingController();
    String selectedCategory = defaultCategory;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('إضافة منتج ($defaultCategory)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'سعر البيع (ج.م)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'سعر الشراء (اختياري)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(labelText: 'الباركود (اختياري)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final price = double.tryParse(priceController.text) ?? 0.0;
                final cost = double.tryParse(costController.text) ?? 0.0;
                final quantity = int.tryParse(quantityController.text) ?? 0;
                
                if (name.isNotEmpty && price > 0 && quantity >= 0) {
                  final item = InventoryItem(
                    name: name,
                    category: selectedCategory,
                    price: price,
                    cost: cost,
                    quantity: quantity,
                    barcode: barcodeController.text,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  context.read<InventoryCubit>().addInventoryItem(item);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
