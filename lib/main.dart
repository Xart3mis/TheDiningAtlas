import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'core/constants/route_names.dart';
import 'models/restaurant_model.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/review_provider.dart';
import 'providers/user_provider.dart';
import 'providers/saved_places_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';

// Screens
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'screens/home/atlas_screen.dart';
import 'screens/home/for_you_screen.dart';
import 'screens/home/stories_screen.dart';
import 'screens/trips/trips_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/restaurant/restaurant_detail_screen.dart';
import 'screens/restaurant/write_review_screen.dart';
import 'screens/restaurant/add_place_screen.dart';
import 'screens/map/map_search_screen.dart';
import 'screens/chat/chat_thread_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/premium/premium_upgrade_screen.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/offline_banner.dart';

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
