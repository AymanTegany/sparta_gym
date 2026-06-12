import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/member_entity.dart';

/// واجهة الـ Repository لإدارة العملاء.
/// تحدد العقود (Contracts) التي يجب أن ينفذها الـ Repository في طبقة الـ Data.
abstract class MembersRepository {
  /// جلب جميع العملاء
  Future<Either<Failure, List<Member>>> getAllMembers();

  /// جلب عميل بالمعرف
  Future<Either<Failure, Member>> getMemberById(int id);

  /// إضافة عميل جديد - يرجع ID العميل الجديد
  Future<Either<Failure, int>> addMember(Member member);

  /// تحديث بيانات عميل
  Future<Either<Failure, Unit>> updateMember(Member member);

  /// حذف عميل
  Future<Either<Failure, Unit>> deleteMember(int id);

  /// البحث في العملاء بالاسم أو رقم الهاتف أو رقم العضوية
  Future<Either<Failure, List<Member>>> searchMembers(String query);
}
