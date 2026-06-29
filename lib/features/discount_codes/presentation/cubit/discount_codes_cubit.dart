import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/discount_code.dart';
import '../../domain/repositories/discount_codes_repository.dart';
import 'discount_codes_state.dart';

class DiscountCodesCubit extends Cubit<DiscountCodesState> {
  final DiscountCodesRepository repository;

  DiscountCodesCubit({required this.repository}) : super(DiscountCodesInitial());

  Future<void> loadDiscountCodes() async {
    emit(DiscountCodesLoading());
    final result = await repository.getDiscountCodes();
    result.fold(
      (failure) => emit(DiscountCodesError(failure)),
      (discountCodes) => emit(DiscountCodesLoaded(discountCodes)),
    );
  }

  Future<void> addDiscountCode(DiscountCode discountCode) async {
    emit(DiscountCodesLoading());
    final result = await repository.addDiscountCode(discountCode);
    result.fold(
      (failure) {
        emit(DiscountCodesError(failure));
        loadDiscountCodes();
      },
      (_) {
        emit(const DiscountCodeActionSuccess('تمت إضافة كود الخصم بنجاح'));
        loadDiscountCodes();
      },
    );
  }

  Future<void> updateDiscountCode(DiscountCode discountCode) async {
    emit(DiscountCodesLoading());
    final result = await repository.updateDiscountCode(discountCode);
    result.fold(
      (failure) {
        emit(DiscountCodesError(failure));
        loadDiscountCodes();
      },
      (_) {
        emit(const DiscountCodeActionSuccess('تم تحديث كود الخصم بنجاح'));
        loadDiscountCodes();
      },
    );
  }

  Future<void> deleteDiscountCode(int id) async {
    emit(DiscountCodesLoading());
    final result = await repository.deleteDiscountCode(id);
    result.fold(
      (failure) {
        emit(DiscountCodesError(failure));
        loadDiscountCodes();
      },
      (_) {
        emit(const DiscountCodeActionSuccess('تم حذف كود الخصم بنجاح'));
        loadDiscountCodes();
      },
    );
  }
}
