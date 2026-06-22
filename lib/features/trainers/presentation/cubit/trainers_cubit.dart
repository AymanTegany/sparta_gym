import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/trainer_entity.dart';
import '../../domain/usecases/add_trainer.dart';
import '../../domain/usecases/delete_trainer.dart';
import '../../domain/usecases/get_all_trainers.dart';
import '../../domain/usecases/update_trainer.dart';
import 'trainers_state.dart';

/// Cubit لإدارة حالات المدربين (Trainers Cubit)
class TrainersCubit extends Cubit<TrainersState> {
  final GetAllTrainers _getAllTrainers;
  final AddTrainer _addTrainer;
  final UpdateTrainer _updateTrainer;
  final DeleteTrainer _deleteTrainer;

  TrainersCubit({
    required GetAllTrainers getAllTrainers,
    required AddTrainer addTrainer,
    required UpdateTrainer updateTrainer,
    required DeleteTrainer deleteTrainer,
  })  : _getAllTrainers = getAllTrainers,
        _addTrainer = addTrainer,
        _updateTrainer = updateTrainer,
        _deleteTrainer = deleteTrainer,
        super(const TrainersInitial());

  /// تحميل المدربين
  Future<void> loadTrainers() async {
    emit(const TrainersLoading());
    final result = await _getAllTrainers(NoParams());
    result.fold(
      (failure) => emit(TrainersError(failure.message)),
      (trainers) => emit(TrainersLoaded(trainers: trainers)),
    );
  }

  /// إضافة مدرب جديد
  Future<void> addTrainer(Trainer trainer) async {
    final result = await _addTrainer(trainer);
    result.fold(
      (failure) => emit(TrainersError(failure.message)),
      (_) {
        emit(const TrainerActionSuccess('تم إضافة المدرب بنجاح'));
        loadTrainers();
      },
    );
  }

  /// تحديث مدرب
  Future<void> updateTrainer(Trainer trainer) async {
    final result = await _updateTrainer(trainer);
    result.fold(
      (failure) => emit(TrainersError(failure.message)),
      (_) {
        emit(const TrainerActionSuccess('تم تحديث بيانات المدرب بنجاح'));
        loadTrainers();
      },
    );
  }

  /// حذف مدرب
  Future<void> deleteTrainer(int id) async {
    final result = await _deleteTrainer(id);
    result.fold(
      (failure) => emit(TrainersError(failure.message)),
      (_) {
        emit(const TrainerActionSuccess('تم حذف المدرب بنجاح'));
        loadTrainers();
      },
    );
  }
}
