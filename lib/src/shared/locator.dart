import 'package:mstudio/src/core/routing/app_router.dart';
import 'package:mstudio/src/datasource/http/dio_config.dart';
import 'package:mstudio/src/datasource/http/example_api.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_notifier.dart';
import 'package:mstudio/src/shared/services/app_logger.dart';
import 'package:mstudio/src/shared/services/storage/local_storage.dart';
import 'package:mstudio/src/shared/services/storage/storage.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance
  ..registerLazySingleton(() => DioConfig())
  ..registerLazySingleton(() => AppRouter())
  ..registerLazySingleton<AppLogger>(() => AppLogger())
  ..registerLazySingleton<Storage>(() => LocalStorage())
  ..registerLazySingleton(() => ExampleApi(dio: locator<DioConfig>().dio))
  ..registerLazySingleton(() => MusicStudioNotifier());
