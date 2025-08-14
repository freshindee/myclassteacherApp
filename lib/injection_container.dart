import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'core/network/network_info.dart';
import 'core/services/crypto_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/update_user.dart';
import 'features/home/data/datasources/note_remote_data_source.dart';
import 'features/home/data/datasources/video_remote_data_source.dart';
import 'features/home/data/datasources/advertisement_remote_data_source.dart';
import 'features/home/data/datasources/contact_remote_data_source.dart';
import 'features/home/data/datasources/timetable_remote_data_source.dart';
import 'features/home/data/repositories/note_repository_impl.dart';
import 'features/home/data/repositories/video_repository_impl.dart';
import 'features/home/data/repositories/advertisement_repository_impl.dart';
import 'features/home/data/repositories/contact_repository_impl.dart';
import 'features/home/data/repositories/timetable_repository_impl.dart';
import 'features/home/domain/repositories/note_repository.dart';
import 'features/home/domain/repositories/video_repository.dart';
import 'features/home/domain/repositories/advertisement_repository.dart';
import 'features/home/domain/repositories/contact_repository.dart';
import 'features/home/domain/repositories/timetable_repository.dart';
import 'features/home/domain/usecases/get_notes.dart';
import 'features/home/domain/usecases/get_videos.dart';
import 'features/home/domain/usecases/get_advertisements.dart';
import 'features/home/domain/usecases/get_contacts.dart';
import 'features/home/domain/usecases/get_timetable_by_grade.dart';
import 'features/home/domain/usecases/get_available_grades.dart';
import 'features/home/domain/usecases/add_video.dart';
import 'features/home/presentation/pages/notes_assignments_page.dart';
import 'features/home/presentation/pages/free_classes_page.dart';
import 'features/home/presentation/pages/class_videos_bloc.dart';
import 'features/home/presentation/pages/contact_bloc.dart';
import 'features/home/presentation/pages/schedule_bloc.dart';
import 'features/payment/data/datasources/payment_remote_data_source.dart';
import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/payment/domain/repositories/payment_repository.dart';
import 'features/payment/domain/usecases/create_payment.dart';
import 'features/payment/domain/usecases/check_access.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/payment/domain/usecases/get_user_subscriptions.dart';
import 'features/payment/domain/usecases/get_user_payments.dart';
import 'features/home/domain/usecases/get_free_videos.dart';
import 'features/home/presentation/pages/free_videos_bloc.dart';
import 'features/home/domain/usecases/get_today_classes.dart';
import 'features/home/domain/repositories/today_class_repository.dart';
import 'features/home/data/repositories/today_class_repository_impl.dart';
import 'features/home/data/datasources/today_class_remote_data_source.dart';
import 'features/home/presentation/pages/today_classes_bloc.dart';
import 'features/home/domain/usecases/get_teachers.dart';
import 'features/home/domain/repositories/teacher_repository.dart';
import 'features/home/data/repositories/teacher_repository_impl.dart';
import 'features/home/data/datasources/teacher_remote_data_source.dart';
import 'features/home/presentation/pages/teachers_bloc.dart';
import 'features/home/presentation/pages/old_videos_bloc.dart';
import 'features/home/domain/usecases/get_free_videos_by_grade.dart';
import 'features/home/domain/usecases/get_notes_by_grade.dart';
import 'features/home/data/datasources/term_test_paper_remote_data_source.dart';
import 'features/home/data/repositories/term_test_paper_repository_impl.dart';
import 'features/home/domain/repositories/term_test_paper_repository.dart';
import 'features/home/domain/usecases/get_term_test_papers.dart';

final sl = GetIt.instance;

void init() {
  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
    ),
  );
  sl.registerFactory(
    () => NotesAssignmentsBloc(
      getNotes: sl(),
      getNotesByGrade: sl(),
    ),
  );
  sl.registerFactory(
    () => FreeClassesBloc(
      getAdvertisements: sl(),
    ),
  );
  sl.registerFactory(
    () => ClassVideosBloc(
      getVideos: sl(),
      getUserPayments: sl(),
    ),
  );
  sl.registerFactory(
    () => PaymentBloc(
      createPayment: sl(),
      checkAccess: sl(),
    ),
  );
  sl.registerFactory(
    () => FreeVideosBloc(
      getFreeVideos: sl(),
      getFreeVideosByGrade: sl(),
    ),
  );
  sl.registerFactory(
    () => TodayClassesBloc(
      getTodayClasses: sl(),
    ),
  );
  sl.registerFactory(
    () => TeachersBloc(
      getTeachers: sl(),
    ),
  );
  sl.registerFactory(
    () => OldVideosBloc(
      getVideos: sl(),
    ),
  );
  sl.registerFactory(
    () => ContactBloc(
      getContacts: sl(),
    ),
  );
  sl.registerFactory(
    () => ScheduleBloc(
      getAvailableGrades: sl(),
      getTimetableByGrade: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => UpdateUser(sl()));
  sl.registerLazySingleton(() => GetVideos(sl()));
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => GetNotesByGrade(sl()));
  sl.registerLazySingleton(() => GetAdvertisements(sl()));
  sl.registerLazySingleton(() => GetContacts(sl()));
  sl.registerLazySingleton(() => GetTimetableByGrade(sl()));
  sl.registerLazySingleton(() => GetAvailableGrades(sl()));
  sl.registerLazySingleton(() => GetTodayClasses(sl()));
  sl.registerLazySingleton(() => AddVideo(sl()));
  sl.registerLazySingleton(() => CreatePayment(sl()));
  sl.registerLazySingleton(() => CheckAccess(sl()));
  sl.registerLazySingleton(() => GetUserSubscriptions(sl()));
  sl.registerLazySingleton(() => GetUserPayments(sl()));
  sl.registerLazySingleton(() => GetFreeVideos(sl()));
  sl.registerLazySingleton(() => GetFreeVideosByGrade(sl()));
  sl.registerLazySingleton(() => GetTeachers(sl()));
  sl.registerLazySingleton(() => GetTermTestPapers(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<AdvertisementRepository>(
    () => AdvertisementRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TodayClassRepository>(
    () => TodayClassRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TimetableRepository>(
    () => TimetableRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TermTestPaperRepository>(
    () => TermTestPaperRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firestore: sl(),
      cryptoService: sl(),
    ),
  );
  sl.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<NoteRemoteDataSource>(
    () => NoteRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<AdvertisementRemoteDataSource>(
    () => AdvertisementRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<ContactRemoteDataSource>(
    () => ContactRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<TodayClassRemoteDataSource>(
    () => TodayClassRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<TimetableRemoteDataSource>(
    () => TimetableRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<TermTestPaperRemoteDataSource>(
    () => TermTestPaperRemoteDataSourceImpl(firestore: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<CryptoService>(() => CryptoService());

  // External
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker());
} 