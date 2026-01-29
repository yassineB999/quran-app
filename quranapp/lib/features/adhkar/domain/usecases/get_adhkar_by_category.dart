import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';
import 'package:quranapp/features/adhkar/domain/repositories/adhkar_repository.dart';

class GetAdhkarByCategory implements UseCase<List<Adhkar>, GetAdhkarParams> {
  final AdhkarRepository repository;

  GetAdhkarByCategory(this.repository);

  @override
  Future<Either<Failure, List<Adhkar>>> call(GetAdhkarParams params) async {
    return await repository.getAdhkar(params.category);
  }
}

class GetAdhkarParams extends Equatable {
  final String category;

  const GetAdhkarParams({required this.category});

  @override
  List<Object?> get props => [category];
}
