import 'package:get_it/get_it.dart';
import 'package:quranapp/features/audio/domain/usecases/check_recitation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quranapp/config/routes/app_router.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/core/network/connectivity_service.dart';
import 'package:quranapp/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:quranapp/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:quranapp/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';
import 'package:quranapp/features/quran/domain/usecases/get_all_surahs.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_page_range.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_bloc.dart';
import 'package:quranapp/features/quran/domain/usecases/get_quran_page.dart';
import 'package:quranapp/features/quran/domain/usecases/save_reading_progress.dart';
import 'package:quranapp/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:quranapp/features/quran/domain/usecases/get_last_reading_state.dart';
import 'package:quranapp/features/quran/domain/usecases/save_reading_state.dart';

// Audio feature imports
import 'package:quranapp/features/audio/data/datasources/reciter_remote_data_source.dart';
import 'package:quranapp/features/audio/data/repositories/reciter_repository_impl.dart';
import 'package:quranapp/features/audio/domain/repositories/reciter_repository.dart';
import 'package:quranapp/features/audio/domain/usecases/get_reciters.dart';
import 'package:quranapp/features/audio/domain/usecases/get_audio_url.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/services/audio_player_service.dart';

import 'package:quranapp/features/home/data/datasources/home_remote_data_source.dart';
import 'package:quranapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:quranapp/features/home/domain/repositories/home_repository.dart';
import 'package:quranapp/features/home/domain/usecases/get_daily_hadith.dart';
import 'package:quranapp/features/home/domain/usecases/get_hijri_date.dart';
import 'package:quranapp/features/home/presentation/bloc/home_cubit.dart';

// Calendar feature imports
import 'package:quranapp/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:quranapp/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:quranapp/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:quranapp/features/calendar/domain/usecases/get_hijri_calendar_month.dart';
import 'package:quranapp/features/calendar/domain/usecases/get_hijri_calendar_year.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_bloc.dart';

// Qiblah feature imports
// Location feature imports
import 'package:quranapp/core/location/data/datasources/location_local_data_source.dart';
import 'package:quranapp/core/location/data/repositories/location_repository_impl.dart';
import 'package:quranapp/core/location/domain/repositories/location_repository.dart';
import 'package:quranapp/core/location/domain/usecases/check_location_permission.dart';
import 'package:quranapp/core/location/domain/usecases/get_current_location.dart';
import 'package:quranapp/core/location/domain/usecases/get_location_stream.dart';

// Qiblah feature imports
import 'package:quranapp/features/qiblah/data/datasources/qiblah_local_data_source.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_remote_data_source.dart';
import 'package:quranapp/features/qiblah/data/repositories/qiblah_repository_impl.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_qiblah_stream.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_bloc.dart';

// Mosques feature imports
import 'package:quranapp/features/mosques/data/datasources/mosque_remote_data_source.dart';
import 'package:quranapp/features/mosques/data/repositories/mosque_repository_impl.dart';
import 'package:quranapp/features/mosques/domain/repositories/mosque_repository.dart';
import 'package:quranapp/features/mosques/domain/usecases/get_nearby_mosques.dart';
import 'package:quranapp/features/mosques/domain/usecases/get_route_to_mosque.dart';
import 'package:quranapp/features/mosques/presentation/bloc/mosque_bloc.dart';
import 'package:quranapp/features/hadith/data/datasources/hadith_remote_data_source.dart';
import 'package:quranapp/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:quranapp/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:quranapp/features/hadith/domain/usecases/get_hadith_by_edition.dart';
import 'package:quranapp/features/hadith/domain/usecases/get_hadith_editions.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_bloc.dart';

// Adhkar feature imports
import 'package:quranapp/features/adhkar/data/datasources/adhkar_remote_data_source.dart';
import 'package:quranapp/features/adhkar/data/repositories/adhkar_repository_impl.dart';
import 'package:quranapp/features/adhkar/domain/repositories/adhkar_repository.dart';
import 'package:quranapp/features/adhkar/domain/usecases/get_adhkar_by_category.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Splash

  //! Core
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton(() => ConnectivityService(connectivity: sl()));

  //! Features - Quran
  sl.registerFactory(
    () => QuranBloc(
      getSurahDetail: sl(),
      getAllSurahs: sl(),
      connectivityService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSurahDetail(sl()));
  sl.registerLazySingleton(() => GetAllSurahs(sl()));
  sl.registerLazySingleton(() => GetQuranPage(sl()));
  sl.registerLazySingleton(() => GetSurahPageRange(sl()));
  sl.registerLazySingleton(() => SaveReadingProgress(sl()));
  sl.registerLazySingleton(() => GetReadingProgress(sl()));
  sl.registerLazySingleton(() => GetLastReadingState(sl()));
  sl.registerLazySingleton(() => SaveReadingState(sl()));

  sl.registerFactory(
    () => QuranReaderBloc(
      getQuranPage: sl(),
      saveReadingProgress: sl(),
      getReadingProgress: sl(),
      saveReadingState: sl(),
    ),
  );

  // Mushaf Bloc
  sl.registerFactory(
    () => MushafBloc(
      getSurahPageRange: sl(),
      getQuranPage: sl(),
      getSurahDetail: sl(),
      checkRecitation: sl(),
      quranRepository: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<QuranRemoteDataSource>(
    () => QuranRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<QuranLocalDataSource>(
    () => QuranLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Audio
  // Audio player service (singleton to maintain player state)
  sl.registerLazySingleton(() => AudioPlayerService());

  // Bloc
  sl.registerFactory(
    () => AudioPlayerBloc(
      audioService: sl(),
      getReciters: sl(),
      getAudioUrl: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetReciters(sl()));
  sl.registerLazySingleton(() => GetAudioUrl(sl()));
  sl.registerLazySingleton(() => CheckRecitation(sl()));

  // Repository
  sl.registerLazySingleton<ReciterRepository>(
    () => ReciterRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ReciterRemoteDataSource>(
    () => ReciterRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Home
  sl.registerFactory(
    () => HomeCubit(
      getDailyHadith: sl(),
      getHijriDate: sl(),
      connectivityService: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetDailyHadith(sl()));
  sl.registerLazySingleton(() => GetHijriDate(sl()));

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Calendar
  sl.registerFactory(
    () => CalendarBloc(
      getHijriCalendarMonth: sl(),
      getHijriCalendarYear: sl(),
      connectivityService: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetHijriCalendarMonth(sl()));
  sl.registerLazySingleton(() => GetHijriCalendarYear(sl()));
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Qiblah
  sl.registerFactory(() => QiblahBloc(getQiblahStream: sl()));
  sl.registerLazySingleton(() => GetQiblahStream(sl()));

  sl.registerLazySingleton<QiblahRepository>(
    () => QiblahRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<QiblahLocalDataSource>(
    () => QiblahLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<QiblahRemoteDataSource>(
    () => QiblahRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Mosques
  sl.registerFactory(
    () => MosqueBloc(
      checkLocationPermission: sl(),
      getCurrentLocation: sl(),
      getLocationStream: sl(),
      getNearbyMosques: sl(),
      connectivityService: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetNearbyMosques(sl()));
  sl.registerLazySingleton(() => GetRouteToMosque(sl()));
  sl.registerLazySingleton<MosqueRepository>(
    () => MosqueRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<MosqueRemoteDataSource>(
    () => MosqueRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Hadith
  sl.registerFactory(
    () => HadithBloc(
      getHadithEditions: sl(),
      getHadithByEdition: sl(),
      connectivityService: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetHadithEditions(sl()));
  sl.registerLazySingleton(() => GetHadithByEdition(sl()));
  sl.registerLazySingleton<HadithRepository>(
    () => HadithRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<HadithRemoteDataSource>(
    () => HadithRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Features - Adhkar
  sl.registerFactory(
    () => AdhkarBloc(getAdhkarByCategory: sl(), connectivityService: sl()),
  );
  sl.registerLazySingleton(() => GetAdhkarByCategory(sl()));
  sl.registerLazySingleton<AdhkarRepository>(
    () => AdhkarRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<AdhkarRemoteDataSource>(
    () => AdhkarRemoteDataSourceImpl(dioClient: sl()),
  );

  //! Core - Location
  sl.registerLazySingleton(() => CheckLocationPermission(sl()));
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => GetLocationStream(sl()));
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => AppRouter());
}
