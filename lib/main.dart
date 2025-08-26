import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'Trips.dart';
import 'explore_screen.dart';
import 'chatbot_screen.dart'; // Import the new chatbot screen

void main() {
  // Ensures that native bindings are initialized before calling SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Mate App',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: const ColorScheme.light().copyWith(
          primary: Colors.black,
          secondary: Colors.deepOrange,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen can maintain its dark theme for impact
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Travel Mate',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isChatbotOpen = false;

  // --- NEW --- Global keys to access child state methods
  final GlobalKey<ExploreScreenState> _exploreKey = GlobalKey();
  final GlobalKey<ItineraryScreenState> _tripsKey = GlobalKey();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // --- UPDATED --- Initialize the list with keys
    _widgetOptions = <Widget>[
      const HomeScreen(),
      ExploreScreen(key: _exploreKey),
      ItineraryScreen(key: _tripsKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _widgetOptions),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _isChatbotOpen
                ? ChatbotScreen(onClose: _toggleChatbot)
                : _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  // --- UPDATED --- This widget now includes the conditional action button
  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chatbot Button
            GestureDetector(
              onTap: _toggleChatbot,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Main Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(Icons.home_outlined, 0),
                  const SizedBox(width: 6),
                  _buildNavItem(Icons.location_on_outlined, 1),
                  const SizedBox(width: 6),
                  _buildNavItem(Icons.card_travel_outlined, 2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // --- NEW --- Conditional Action Button
            _buildConditionalActionButton(),
          ],
        ),
      ),
    );
  }

  // --- NEW --- This widget builds the button based on the selected screen
  Widget _buildConditionalActionButton() {
    Widget button;
    switch (_selectedIndex) {
      case 1: // Explore Screen
        button = _buildActionButton(
          icon: Icons.my_location,
          onTap: () => _exploreKey.currentState?.goToCurrentUserLocation(),
        );
        break;
      case 2: // Trips Screen
        button = _buildActionButton(
          icon: Icons.add,
          onTap: () => _tripsKey.currentState?.addTrip(),
        );
        break;
      default: // Home Screen or others
        button = const SizedBox(
          width: 44,
        ); // Takes up the same space as the button
        break;
    }
    return AnimatedOpacity(
      opacity: _selectedIndex == 0 ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: button,
    );
  }

  // --- NEW --- Helper to build the action button's UI
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade400,
          size: 26,
        ),
      ),
    );
  }
}
