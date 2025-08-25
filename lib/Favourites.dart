import 'package:flutter/material.dart';

void main() {
  runApp(const FavouritesScreen());
}

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        brightness: Brightness.dark, // Set overall theme to dark
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black, // Dark background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // AppBar background
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3.0,
              color: Colors.white, // Indicator color
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1B202D),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed, // Ensure all items are visible
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
        // Define text theme for better consistency
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: TextStyle(color: Colors.white70),
        ),
        fontFamily: 'Inter', // Assuming 'Inter' font is available or default
      ),
      home: const TravelScreen(),
    );
  }
}

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _selectedIndex =
      1; // Set initial selected index for bottom nav to Explore

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section Placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                16.0,
              ), // Rounded corners for the map
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.blueGrey[900], // Dark placeholder color
                child: Image.network(
                  'https://placehold.co/600x200/2C3246/FFFFFF?text=Map+of+Paris', // Placeholder map image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'Map could not be loaded',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Tab Bar
          Align(
            alignment: Alignment.center,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Allows tabs to scroll if many
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              tabs: const [
                Tab(text: 'Attractions'),
                Tab(text: 'Restaurants'),
                Tab(text: 'Activities'),
              ],
            ),
          ),
          // Filter/Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterChip('All', Icons.arrow_drop_down),
                _buildFilterChip('Popular', Icons.arrow_drop_down),
                _buildFilterChip('Recommended', Icons.arrow_drop_down),
              ],
            ),
          ),
          // Scrollable Content based on Tab (Attractions List)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttractionList(), // Attractions tab content
                Center(
                  child: Text(
                    'Restaurants Content',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Center(
                  child: Text(
                    'Activities Content',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build filter chips
  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B303E), // Darker background for chips
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(width: 4.0),
          Icon(icon, size: 18, color: Colors.white54),
        ],
      ),
    );
  }

  // Helper method to build the attraction list
  Widget _buildAttractionList() {
    // Sample data for attractions
    final List<Map<String, String>> attractions = [
      {
        'name': 'Eiffel Tower',
        'description':
            'Iconic wrought-iron lattice tower on the Champ de Mars in Paris.',
        'image': 'https://placehold.co/150x100/A0A0A0/000000?text=Eiffel+Tower',
      },
      {
        'name': 'Louvre Museum',
        'description':
            'World\'s largest art museum and a historic monument in Paris.',
        'image':
            'https://placehold.co/150x100/A0A0A0/000000?text=Louvre+Museum',
      },
      {
        'name': 'Arc de Triomphe',
        'description':
            'Triumphal arch at the western end of the Champs-Élysées.',
        'image':
            'https://placehold.co/150x100/A0A0A0/000000?text=Arc+de+Triomphe',
      },
      {
        'name': 'Notre Dame Cathedral',
        'description':
            'Medieval Catholic cathedral on the Île de la Cité in Paris.',
        'image': 'https://placehold.co/150x100/A0A0A0/000000?text=Notre+Dame',
      },
      {
        'name': 'Sacré-Cœur Basilica',
        'description': 'Roman Catholic church and minor basilica in Paris.',
        'image': 'https://placehold.co/150x100/A0A0A0/000000?text=Sacre-Coeur',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: attractions.length,
      itemBuilder: (context, index) {
        final attraction = attractions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attraction',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      attraction['name']!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      attraction['description']!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // Rounded corners for images
                child: Image.network(
                  attraction['image']!,
                  width: 120,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 90,
                      color: Colors.grey[700],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
