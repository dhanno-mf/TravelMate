import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin, pow, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart'; // Import the new package
import 'places_search_delegate.dart'; // Import the search delegate
import 'explore_screen.dart'; // Import for the API key

// Data class for Stays
class Stay {
  final String name;
  final String? imageUrl;
  final double distance;
  final String priceLevel;

  Stay({
    required this.name,
    this.imageUrl,
    required this.distance,
    required this.priceLevel,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
    'distance': distance,
    'priceLevel': priceLevel,
  };

  factory Stay.fromJson(Map<String, dynamic> json) => Stay(
    name: json['name'],
    imageUrl: json['imageUrl'],
    distance: json['distance'],
    priceLevel: json['priceLevel'],
  );
}

// --- NEW --- Data class for Attractions
class Attraction {
  final String name;
  final String? imageUrl;
  final double distance;
  final double rating;

  Attraction({
    required this.name,
    this.imageUrl,
    required this.distance,
    required this.rating,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
    'distance': distance,
    'rating': rating,
  };

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
    name: json['name'],
    imageUrl: json['imageUrl'],
    distance: json['distance'],
    rating: json['rating'],
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentCity = "Loading...";
  late TabController _tabController;
  LocationData? _currentLocationData;

  List<Stay> _nearbyStays = [];
  bool _isLoadingStays = false;

  // --- NEW --- State for Attractions tab
  List<Attraction> _nearbyAttractions = [];
  bool _isLoadingAttractions = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _updateLocationAndFetchData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // --- UPDATED --- Trigger fetch when a tab is selected
  void _handleTabSelection() {
    if (_tabController.index == 1 && _nearbyStays.isEmpty) {
      _loadCachedStays();
      _fetchNearbyStays();
    } else if (_tabController.index == 2 && _nearbyAttractions.isEmpty) {
      _loadCachedAttractions();
      _fetchNearbyAttractions();
    }
  }

  Future<void> _updateLocationAndFetchData() async {
    await _loadCachedLocation();
    await _getCurrentLocation();
    // After getting location, trigger the fetch for the currently selected tab
    _handleTabSelection();
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCity = prefs.getString('lastKnownCity');
    if (cachedCity != null && mounted) {
      setState(() {
        _currentCity = cachedCity;
      });
    }
  }

  Future<void> _loadCachedStays() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStaysJson = prefs.getString('cachedStays');
    if (cachedStaysJson != null && mounted) {
      final List<dynamic> decodedList = json.decode(cachedStaysJson);
      setState(() {
        _nearbyStays = decodedList.map((item) => Stay.fromJson(item)).toList();
      });
    }
  }

  // --- NEW --- Load cached attractions from local storage
  Future<void> _loadCachedAttractions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedAttractionsJson = prefs.getString('cachedAttractions');
    if (cachedAttractionsJson != null && mounted) {
      final List<dynamic> decodedList = json.decode(cachedAttractionsJson);
      setState(() {
        _nearbyAttractions = decodedList
            .map((item) => Attraction.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      debugPrint("Checking location service...");
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location service disabled, requesting...");
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() => _currentCity = "Location disabled");
          return;
        }
      }

      debugPrint("Checking location permission...");
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        debugPrint("Location permission denied, requesting...");
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (!mounted) return;
          setState(() => _currentCity = "Permission denied");
          return;
        }
      }

      debugPrint("Fetching location data...");
      _currentLocationData = await location.getLocation();
      debugPrint(
        "Location data received: Lat: ${_currentLocationData?.latitude}, Lng: ${_currentLocationData?.longitude}",
      );

      if (_currentLocationData?.latitude != null &&
          _currentLocationData?.longitude != null) {
        debugPrint("Geocoding coordinates...");
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          _currentLocationData!.latitude!,
          _currentLocationData!.longitude!,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final newCity = "${placemark.locality}, ${placemark.isoCountryCode}";

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastKnownCity', newCity);

          if (!mounted) return;
          setState(() {
            _currentCity = newCity;
          });
        }
      }
    } catch (e) {
      debugPrint("An error occurred in _getCurrentLocation: $e");
      if (!mounted) return;
      setState(() => _currentCity = "Could not get city");
    }
  }

  Future<void> _fetchNearbyStays() async {
    if (_currentLocationData == null) {
      await Future.delayed(const Duration(seconds: 1));
      if (_currentLocationData == null) return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingStays = true;
    });

    try {
      final lat = _currentLocationData!.latitude;
      final lng = _currentLocationData!.longitude;

      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=lodging&keyword=stay&key=$kGoogleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        List<Stay> fetchedStays = [];

        for (var result in results) {
          String? imageUrl;
          if (result['photos'] != null &&
              (result['photos'] as List).isNotEmpty) {
            final photoReference = result['photos'][0]['photo_reference'];
            imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$kGoogleApiKey';
          }

          final placeLat = result['geometry']['location']['lat'];
          final placeLng = result['geometry']['location']['lng'];
          final distance = _calculateDistance(
            LatLng(lat!, lng!),
            LatLng(placeLat, placeLng),
          );

          String priceLevelString = '';
          if (result['price_level'] != null) {
            priceLevelString = '\$' * (result['price_level'] as int);
          } else {
            priceLevelString = 'N/A';
          }

          final stay = Stay(
            name: result['name'] ?? 'No name',
            imageUrl: imageUrl,
            distance: distance,
            priceLevel: priceLevelString,
          );
          fetchedStays.add(stay);
        }

        final prefs = await SharedPreferences.getInstance();
        final List<Map<String, dynamic>> staysToCache = fetchedStays
            .map((stay) => stay.toJson())
            .toList();
        await prefs.setString('cachedStays', json.encode(staysToCache));

        if (!mounted) return;
        setState(() {
          _nearbyStays = fetchedStays;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stays: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStays = false;
        });
      }
    }
  }

  // --- NEW --- Function to fetch nearby attractions
  Future<void> _fetchNearbyAttractions() async {
    if (_currentLocationData == null) {
      await Future.delayed(const Duration(seconds: 1));
      if (_currentLocationData == null) return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingAttractions = true;
    });

    try {
      final lat = _currentLocationData!.latitude;
      final lng = _currentLocationData!.longitude;

      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=tourist_attraction&key=$kGoogleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        List<Attraction> fetchedAttractions = [];

        for (var result in results) {
          String? imageUrl;
          if (result['photos'] != null &&
              (result['photos'] as List).isNotEmpty) {
            final photoReference = result['photos'][0]['photo_reference'];
            imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$kGoogleApiKey';
          }

          final placeLat = result['geometry']['location']['lat'];
          final placeLng = result['geometry']['location']['lng'];
          final distance = _calculateDistance(
            LatLng(lat!, lng!),
            LatLng(placeLat, placeLng),
          );

          fetchedAttractions.add(
            Attraction(
              name: result['name'] ?? 'No name',
              imageUrl: imageUrl,
              distance: distance,
              rating: (result['rating'] ?? 0.0).toDouble(),
            ),
          );
        }

        final prefs = await SharedPreferences.getInstance();
        final List<Map<String, dynamic>> attractionsToCache = fetchedAttractions
            .map((attr) => attr.toJson())
            .toList();
        await prefs.setString(
          'cachedAttractions',
          json.encode(attractionsToCache),
        );

        if (!mounted) return;
        setState(() {
          _nearbyAttractions = fetchedAttractions;
        });
      }
    } catch (e) {
      debugPrint("Error fetching attractions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttractions = false;
        });
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371; // Radius of Earth in kilometers
    double lat1 = start.latitude;
    double lon1 = start.longitude;
    double lat2 = end.latitude;
    double lon2 = end.longitude;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);

    double a =
        pow(sin(dLat / 2), 2) + pow(sin(dLon / 2), 2) * cos(lat1) * cos(lat2);
    double c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<void> _handleSearchTap() async {
    final String? result = await showSearch(
      context: context,
      delegate: PlacesSearchDelegate(),
    );

    if (result != null && result.isNotEmpty) {
      debugPrint("Search result from home screen: $result");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(child: Center(child: Text("Side Menu"))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildTabBar(),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDestinationsList(),
                    _buildStaysList(),
                    _buildAttractionsList(), // New list for Attractions
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Column(
          children: [
            const Text(
              'Location',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.black, size: 18),
                const SizedBox(width: 4),
                Text(
                  _currentCity,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  onPressed: _updateLocationAndFetchData,
                ),
              ],
            ),
          ],
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, right: 10),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _handleSearchTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            const Text(
              'Search destination...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: 'Trips'),
        Tab(text: 'Stays'),
        Tab(text: 'Attractions'), // Renamed from Activities
      ],
    );
  }

  Widget _buildDestinationsList() {
    return ListView(
      children: [
        _buildStayCard(
          Stay(
            imageUrl: 'https://picsum.photos/400/600',
            name: 'Hirosima Place',
            distance: 0,
            priceLevel: '\$90.00/ Mount',
          ),
        ),
        const SizedBox(height: 16),
        _buildStayCard(
          Stay(
            imageUrl: 'https://picsum.photos/401/601',
            name: 'Another Place',
            distance: 0,
            priceLevel: '\$120.00/ Mount',
          ),
        ),
      ],
    );
  }

  Widget _buildStaysList() {
    if (_isLoadingStays && _nearbyStays.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nearbyStays.isEmpty) {
      return const Center(child: Text("No nearby stays found."));
    }
    return ListView.builder(
      itemCount: _nearbyStays.length,
      itemBuilder: (context, index) {
        final stay = _nearbyStays[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildStayCard(stay),
        );
      },
    );
  }

  // --- NEW --- Widget to build the list for the "Attractions" tab
  Widget _buildAttractionsList() {
    if (_isLoadingAttractions && _nearbyAttractions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nearbyAttractions.isEmpty) {
      return const Center(child: Text("No nearby attractions found."));
    }
    return ListView.builder(
      itemCount: _nearbyAttractions.length,
      itemBuilder: (context, index) {
        final attraction = _nearbyAttractions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildAttractionCard(attraction),
        );
      },
    );
  }

  Widget _buildStayCard(Stay stay) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 350,
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: stay.imageUrl ?? 'https://picsum.photos/400/600',
              fit: BoxFit.cover,
              imageErrorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stay.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stay.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rate: ${stay.priceLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW --- Card widget for attractions
  Widget _buildAttractionCard(Attraction attraction) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 350,
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: attraction.imageUrl ?? 'https://picsum.photos/400/600',
              fit: BoxFit.cover,
              imageErrorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${attraction.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attraction.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${attraction.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
