import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home.dart';
import 'theme.dart';
import 'widgets/background_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Prefer dark status bar icons on the dark background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NauticomApp());
}

class NauticomApp extends StatelessWidget {
  const NauticomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Submarine Control',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppProvider>().isLoggedIn;
    // final isLoggedIn = true;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isLoggedIn
          ? const BackgroundWrapper(key: ValueKey('main'), child: MainShell())
          : const BackgroundWrapper(
              key: ValueKey('login'), child: LoginScreen()),
    );
  }
}
