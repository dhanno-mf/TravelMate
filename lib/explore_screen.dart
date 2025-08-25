import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'places_search_delegate.dart'; // Import the new search delegate

// --- IMPORTANT ---
// Replace this with your Google Maps API Key for search to work.
const String kGoogleApiKey = "AIzaSyBhbFvTs_-7I5_x3seQIvG8kziLoJz9PNE";

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Controller for the map
  GoogleMapController? _mapController;

  // Location package instance
  final Location _location = Location();

  // Initial camera position (Varanasi, India as a fallback)
  static const LatLng _initialPosition = LatLng(25.3176, 82.9739);

  // Set of markers to display on the map
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('Rouen'),
      position: LatLng(49.4432, 1.0999),
      infoWindow: InfoWindow(title: 'Rouen', snippet: '\$1,200.00/night'),
    ),
    const Marker(
      markerId: MarkerId('Paris'),
      position: LatLng(48.8566, 2.3522),
      infoWindow: InfoWindow(title: 'Paris', snippet: 'Capital of France'),
    ),
    const Marker(
      markerId: MarkerId('Rennes'),
      position: LatLng(48.1173, -1.6778),
      infoWindow: InfoWindow(title: 'Rennes', snippet: '\$1,075.00'),
    ),
  };

  @override
  void initState() {
    super.initState();
    // Get the current location when the screen initializes
    _goToCurrentUserLocation();

    // Add a check to warn the user if the API key is missing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kGoogleApiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
        debugPrint(
          "--- WARNING: Google Maps API Key is not set. Search will not work. ---",
        );
      }
    });
  }

  // Method to get user's location and move the camera
  Future<void> _goToCurrentUserLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return; // Services are disabled, can't get location.
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // Permissions are denied, can't get location.
      }
    }

    locationData = await _location.getLocation();

    if (locationData.latitude != null && locationData.longitude != null) {
      final LatLng currentUserLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      // Animate camera to the user's location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentUserLocation,
            zoom: 14.0, // Zoom in closer to the user
          ),
        ),
      );

      // Add a marker for the user's current location
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentUserLocation,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Method to get place details and move the map
  Future<void> _getPlaceDetails(String placeId) async {
    // Return early if the API key is not set.
    if (kGoogleApiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
      debugPrint(
        "--- ERROR: Cannot fetch place details. API Key is missing. ---",
      );
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      if (result != null) {
        final lat = result['geometry']['location']['lat'];
        final lng = result['geometry']['location']['lng'];
        final searchedLocation = LatLng(lat, lng);

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: searchedLocation, zoom: 15),
          ),
        );

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: searchedLocation,
              infoWindow: InfoWindow(
                title: result['name'],
                snippet: result['formatted_address'],
              ),
            ),
          );
        });
      }
    }
  }

  // --- NEW --- Method to show the search delegate
  Future<void> _handleSearchTap() async {
    final String? placeId = await showSearch(
      context: context,
      delegate: PlacesSearchDelegate(),
    );

    if (placeId != null) {
      _getPlaceDetails(placeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The interactive Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 7.0,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
          ),
          // UI Elements on top of the map
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(),
                ),
                _buildFilterChips(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 100.0,
                    left: 16,
                    right: 16,
                  ),
                  child: _buildLocationCard(),
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating action button to re-center on user's location
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentUserLocation,
        backgroundColor: Colors.black,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  // --- UPDATED --- Search bar is now a GestureDetector
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _handleSearchTap,
      child: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: EdgeInsetsDirectional.only(
          start: 10,
          end: 4,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Search name, city, etc...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip(
            label: '',
            icon: Icons.tune,
            isSelected: false,
            isBlack: true,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Villa', icon: Icons.home, isSelected: true),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Hotel', icon: Icons.hotel),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Mansion', icon: Icons.location_city),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Apartment', icon: Icons.apartment),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isSelected = false,
    bool isBlack = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isBlack
            ? Colors.black
            : (isSelected ? Colors.black : Colors.white),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isBlack
                ? Colors.white
                : (isSelected ? Colors.white : Colors.black),
            size: 20,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Rouen, France',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Check in & out',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '20-22 Nov',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Guests',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        '2 Guests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '\$1,200.00/night',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://picsum.photos/400',
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('4.7'),
                          SizedBox(width: 8),
                          Text(
                            '786 Reviews',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
