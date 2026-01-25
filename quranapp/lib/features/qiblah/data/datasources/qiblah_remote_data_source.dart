import 'package:quranapp/core/network/dio_client.dart';

abstract class QiblahRemoteDataSource {
  // Methods removed as they are moved to Mosques feature
}

class QiblahRemoteDataSourceImpl implements QiblahRemoteDataSource {
  final DioClient dioClient;

  QiblahRemoteDataSourceImpl({required this.dioClient});
}
