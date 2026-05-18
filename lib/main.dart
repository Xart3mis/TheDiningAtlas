import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'core/service_provider.dart';
import 'core/constants/route_names.dart';

// Screens
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/atlas_screen.dart';
import 'screens/home/for_you_screen.dart';
import 'screens/home/stories_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/trips/trips_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'screens/restaurant/restaurant_detail_screen.dart';
import 'screens/restaurant/write_review_screen.dart';
import 'screens/restaurant/edit_review_screen.dart';
import 'models/review_model.dart';
import 'screens/restaurant/add_place_screen.dart';
import 'screens/map/map_search_screen.dart';
import 'screens/chat/chat_thread_screen.dart';
import 'screens/premium/premium_upgrade_screen.dart';
import 'models/restaurant_model.dart';
import 'widgets/offline_banner.dart';
import 'widgets/shared_widgets.dart';
import 'providers/location_provider.dart';

final mainShellKey = GlobalKey<_MainShellState>();

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
        // LocationProvider is standalone (no service interface needed)
        ChangeNotifierProvider(create: (_) => LocationProvider()),
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
        return MaterialPageRoute(builder: (_) => MainShell(key: mainShellKey));
      case RouteNames.kRestaurantDetail:
        if (settings.arguments is! RestaurantModel) {
          return MaterialPageRoute(builder: (_) => const AuthGate());
        }
        return MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
                restaurant: settings.arguments as RestaurantModel));
      case RouteNames.kWriteReview:
        if (settings.arguments is! RestaurantModel) {
          return MaterialPageRoute(builder: (_) => const AuthGate());
        }
        return MaterialPageRoute(
            builder: (_) => WriteReviewScreen(
                restaurant: settings.arguments as RestaurantModel));
      case RouteNames.kAddPlace:
        return MaterialPageRoute(builder: (_) => const AddPlaceScreen());
      case RouteNames.kMapSearch:
        return MaterialPageRoute(builder: (_) => const MapSearchScreen());
      case RouteNames.kChatThread:
        final args = settings.arguments;
        if (args is! Map<String, String> ||
            !args.containsKey('otherUid') ||
            !args.containsKey('placeId') ||
            !args.containsKey('otherName')) {
          return MaterialPageRoute(builder: (_) => const AuthGate());
        }
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
      case RouteNames.kEditReview:
        final review = settings.arguments as ReviewModel;
        return MaterialPageRoute(
            builder: (_) => EditReviewScreen(review: review));
      case RouteNames.kPlanTrip:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(
              backgroundColor: AppColors.cream,
              elevation: 0,
              leading: const BackButton(color: AppColors.ink),
              title: Text('Plan a Trip',
                  style: GoogleFonts.fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            body: Center(
              child: Text('Coming soon',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.warmGrey)),
            ),
          ),
        );
      case RouteNames.kNotifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void switchTab(int index) {
    mainShellKey.currentState?._switchTab(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    AtlasScreen(),
    ForYouScreen(),
    StoriesScreen(),
    NotificationsScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  void _switchTab(int index) {
    if (index < 0 || index >= _screens.length || index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AtlasBottomNav(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
      floatingActionButton: _currentIndex <= 1
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, RouteNames.kAddPlace),
              backgroundColor: AppColors.terracotta,
              child: const Icon(Icons.add_location_alt, color: Colors.white),
            )
          : null,
    );
  }
}
