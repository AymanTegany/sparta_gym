import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';
import '../../../../features/shifts/presentation/cubit/shifts_cubit.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosCubit>().loadPos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SidebarLayout(
      activePage: 'pos',
      title: 'نقطة البيع (POS)',
      body: BlocBuilder<PosCubit, PosState>(
        builder: (context, state) {
          if (state is PosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PosLoaded) {
            final inventoryItems = state.inventoryItems.where((i) => i.quantity > 0).toList();
            final cart = state.cart;
            
            double totalAmount = 0;
            for (var entry in cart.entries) {
              final item = state.inventoryItems.firstWhere((e) => e.id == entry.key);
              totalAmount += item.price * entry.value;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // قسم المنتجات
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيع منتجات الجيم',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: inventoryItems.isEmpty
                            ? Center(child: Text('لا يوجد منتجات متاحة في المخزون'))
                            : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: inventoryItems.length,
                            itemBuilder: (context, index) {
                              final item = inventoryItems[index];
                              final cartQuantity = cart[item.id!] ?? 0;
                              return Card(
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: cartQuantity > 0 
                                        ? theme.colorScheme.primary 
                                        : theme.dividerColor.withOpacity(0.1), 
                                    width: cartQuantity > 0 ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      context.read<PosCubit>().addToCart(item);
                                    },
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.inventory_2_outlined, 
                                                  size: 24, 
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                item.name, 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'المتاح: ${item.quantity}', 
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.price} ج.م', 
                                                style: TextStyle(
                                                  color: theme.colorScheme.primary, 
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (cartQuantity > 0)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$cartQuantity',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // قسم الفاتورة وعربة التسوق
                Expanded(
                  flex: 1,
                  child: Container(
                    color: theme.cardColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الفاتورة',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        Expanded(
                          child: cart.isEmpty
                            ? const Center(
                                child: Text('عربة التسوق فارغة', style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.builder(
                                itemCount: cart.length,
                                itemBuilder: (context, index) {
                                  final itemId = cart.keys.elementAt(index);
                                  final quantity = cart.values.elementAt(index);
                                  final item = state.inventoryItems.firstWhere((e) => e.id == itemId);
                                  
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${item.price} ج.م x $quantity'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${item.price * quantity} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () {
                                            context.read<PosCubit>().removeFromCart(item);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('$totalAmount ج.م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: cart.isEmpty ? null : () async {
                              final shiftId = context.read<ShiftsCubit>().currentShiftId;
                              await context.read<PosCubit>().checkout('كاش', shiftId: shiftId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إصدار الفاتورة وحفظها بنجاح!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('دفع وإصدار الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('حدث خطأ في تحميل نقطة البيع'));
        },
      ),
    );
  }
}
