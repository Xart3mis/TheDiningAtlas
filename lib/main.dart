import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/atlas_screen.dart';
import 'screens/for_you_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/shared_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DiningAtlasApp());
}

class DiningAtlasApp extends StatelessWidget {
  const DiningAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'The Dining Atlas',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(mainApp: MainShell()),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    AtlasScreen(),
    ForYouScreen(),
    StoriesScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AtlasBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
