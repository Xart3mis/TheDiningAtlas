import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'screens/atlas_screen.dart';
import 'screens/for_you_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/offline_banner.dart';

import 'core/service_provider.dart';

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
    return MultiProvider(
      providers: [
        ...ServiceProvider.getProviders(),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'The Dining Atlas',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        onGenerateRoute: _generateRoute,
        home: const OfflineBanner(child: AuthGate()),
      ),
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.kLogin:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.kRegister:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.kForgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case RouteNames.kOnboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingShell());
      case RouteNames.kMain:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case RouteNames.kRestaurantDetail:
        final restaurant = settings.arguments as RestaurantModel;
        return MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant));
      case RouteNames.kWriteReview:
        final restaurant = settings.arguments as RestaurantModel;
        return MaterialPageRoute(
            builder: (_) => WriteReviewScreen(restaurant: restaurant));
      case RouteNames.kAddPlace:
        return MaterialPageRoute(builder: (_) => const AddPlaceScreen());
      case RouteNames.kMapSearch:
        return MaterialPageRoute(builder: (_) => const MapSearchScreen());
      case RouteNames.kChatThread:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
                  otherUid: args['otherUid']!,
                  placeId: args['placeId']!,
                  otherName: args['otherName']!,
                ));
      case RouteNames.kSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.kPremiumUpgrade:
        return MaterialPageRoute(builder: (_) => const PremiumUpgradeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
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
