import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:url_launcher/url_launcher.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/add_video_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

/// Play Store URL for My Class Teacher app. Used when app_config has update_the_app: true.
const String kPlayStoreAppUrl =
    'https://play.google.com/store/apps/details?id=com.fusionlkitsolution.myclassteacher';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      if (!DefaultFirebaseOptions.isWebConfigured) {
        throw StateError('Firebase web configuration is incomplete.');
      }
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    runApp(_FirebaseInitErrorApp(message: e.toString()));
    return;
  }

  if (!kIsWeb) {
    // Crashlytics is configured for mobile platforms.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(const CheckAuthStatus()),
      child: MaterialApp(
        title: 'Fusion Bits Classes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          splashFactory: InkRipple.splashFactory,
        ),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomePage(),
          '/add-video': (context) => const AddVideoPage(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == FormzStatus.submissionSuccess && state.user != null) {
          // Update required: open app in Play Store
          if (state.forceUpdateRequired) {
            return _UpdateRequiredScreen(playStoreUrl: kPlayStoreAppUrl);
          }
          // Show loading until initial cache sync completes (first launch / no cache)
          if (state.isInitialSyncInProgress) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your data...'),
                  ],
                ),
              ),
            );
          }
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

class _UpdateRequiredScreen extends StatefulWidget {
  const _UpdateRequiredScreen({required this.playStoreUrl});

  final String playStoreUrl;

  @override
  State<_UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<_UpdateRequiredScreen> {
  Future<void> _openPlayStore() async {
    final uri = Uri.parse(widget.playStoreUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UpdateRequiredScreen: could not open Play Store: $e');
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPlayStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.system_update_alt, size: 80, color: Colors.blue.shade700),
              const SizedBox(height: 24),
              Text(
                'Update required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A new version of the app is available. Please update to continue.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _openPlayStore,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Play Store'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirebaseInitErrorApp extends StatelessWidget {
  const _FirebaseInitErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Firebase initialization failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
