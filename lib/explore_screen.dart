import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' show cos, sqrt, asin, sin, pow, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'places_search_delegate.dart';

// --- IMPORTANT ---
// API Key has been added.
const String kGoogleApiKey = "AIzaSyBhbFvTs_-7I5_x3seQIvG8kziLoJz9PNE";

// --- UPDATED --- Data class now includes an optional imageUrl
class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double rating;
  final int totalReviews;
  final String? imageUrl; // Can be null if no photo is available

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.rating,
    required this.totalReviews,
    this.imageUrl,
  });
}

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
  LatLng? _currentUserLocation;

  // State for the selected category
  String _selectedCategory = 'villa'; // Default selected category

  // State variable to manage the visibility and content of the location card
  PlaceDetails? _selectedPlace;

  // Initial camera position (fallback)
  static const LatLng _initialPosition = LatLng(48.8566, 2.3522);

  // Set of markers to display on the map
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Get the current location when the screen initializes
    _fetchInitialLocation();
  }

  // Helper function to create the custom user location marker icon
  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    int size,
    Color color, {
    Color borderColor = Colors.white,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint borderPaint = Paint()..color = borderColor;
    final Paint fillPaint = Paint()..color = color;

    // Draw the white border circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);
    // Draw the inner blue circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 * 0.8, fillPaint);

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // This function now handles the smart re-centering and refreshing logic
  Future<void> _goToCurrentUserLocation() async {
    // If we have a stored location, check if we should re-center or refresh.
    if (_currentUserLocation != null && _mapController != null) {
      final LatLngBounds visibleRegion = await _mapController!
          .getVisibleRegion();
      // If the user's location is NOT on screen, just pan back to it.
      if (!visibleRegion.contains(_currentUserLocation!)) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentUserLocation!, zoom: 14.0),
          ),
        );
        return; // Stop here, no need to refresh yet.
      }
    }
    // If we don't have a location OR if the user is already centered and taps again,
    // then perform a full refresh of the GPS location.
    await _fetchInitialLocation(forceRefresh: true);
  }

  // Renamed for clarity, this is the main location fetching logic
  Future<void> _fetchInitialLocation({bool forceRefresh = false}) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationData = await _location.getLocation();

    if (locationData.latitude != null && locationData.longitude != null) {
      _currentUserLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      final BitmapDescriptor customIcon = await _createCustomMarkerBitmap(
        80,
        Colors.blue.shade600,
      );

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentUserLocation!,
            icon: customIcon,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentUserLocation!, zoom: 14.0),
        ),
      );

      // Only fetch nearby places on the very first load or a forced refresh
      if (forceRefresh || _markers.length <= 1) {
        _fetchNearbyPlaces(_selectedCategory);
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Method to fetch nearby places based on category
  Future<void> _fetchNearbyPlaces(String category) async {
    if (_currentUserLocation == null) return;

    final String placeType = _getPlaceTypeForCategory(category);
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}&radius=5000&type=$placeType&key=$kGoogleApiKey';

    await _executePlaceSearch(url, 'category');
  }

  // Method for manual text search
  Future<void> _performTextSearch(String query) async {
    if (_currentUserLocation == null) return;

    final String url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&location=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}&radius=5000&key=$kGoogleApiKey';

    await _executePlaceSearch(url, 'search');
  }

  // Generic helper to execute search, update markers, and adjust camera
  Future<void> _executePlaceSearch(String url, String searchType) async {
    if (kGoogleApiKey == "YOUR_GOOGLE_MAPS_API_KEY") return;

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      debugPrint("Found ${results.length} places for $searchType.");

      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No places found nearby.'),
            backgroundColor: Colors.black87,
          ),
        );
      }

      // Create a list of new markers from the results
      List<Marker> newMarkers = [];
      for (var result in results) {
        final lat = result['geometry']['location']['lat'];
        final lng = result['geometry']['location']['lng'];
        final placeLocation = LatLng(lat, lng);
        final placeId = result['place_id'];
        final placeName = result['name'];

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: placeLocation,
            infoWindow: InfoWindow(title: placeName),
            onTap: () => _getPlaceDetails(placeId),
          ),
        );
      }

      // Update the state with the new markers
      setState(() {
        _markers.removeWhere((m) => m.markerId.value != 'currentLocation');
        _markers.addAll(newMarkers);
      });

      // Adjust camera to show all new markers
      if (newMarkers.isNotEmpty) {
        _zoomToFitMarkers(newMarkers);
      }
    }
  }

  // Helper function to calculate distance between two coordinates
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

  // Helper function to calculate bounds and zoom the camera within a radius
  void _zoomToFitMarkers(List<Marker> markers) {
    if (markers.isEmpty ||
        _mapController == null ||
        _currentUserLocation == null)
      return;

    const double maxDistance = 15.0; // 15km radius
    final List<Marker> nearbyMarkers = markers
        .where(
          (marker) =>
              _calculateDistance(_currentUserLocation!, marker.position) <=
              maxDistance,
        )
        .toList();

    if (nearbyMarkers.isEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentUserLocation!, zoom: 12.0),
        ),
      );
      return;
    }

    if (nearbyMarkers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: nearbyMarkers.first.position, zoom: 15.0),
        ),
      );
      return;
    }

    List<LatLng> points = nearbyMarkers.map((m) => m.position).toList();
    points.add(_currentUserLocation!);

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60.0), // 60.0 is for padding
    );
  }

  String _getPlaceTypeForCategory(String category) {
    switch (category) {
      case 'villa':
      case 'apartment':
        return 'lodging';
      case 'hotel':
        return 'hotel';
      case 'mansion':
        return 'tourist_attraction';
      default:
        return 'point_of_interest';
    }
  }

  // --- UPDATED --- This function now fetches photo details
  Future<void> _getPlaceDetails(String placeId) async {
    if (kGoogleApiKey == "YOUR_GOOGLE_MAPS_API_KEY") return;

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,rating,user_ratings_total,photos&key=$kGoogleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      if (result != null) {
        String? imageUrl;
        // Check if there are photos and construct the URL
        if (result['photos'] != null && (result['photos'] as List).isNotEmpty) {
          final photoReference = result['photos'][0]['photo_reference'];
          imageUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$kGoogleApiKey';
        }

        setState(() {
          _selectedPlace = PlaceDetails(
            placeId: placeId,
            name: result['name'] ?? 'No name',
            address: result['formatted_address'] ?? 'No address',
            rating: (result['rating'] ?? 0.0).toDouble(),
            totalReviews: result['user_ratings_total'] ?? 0,
            imageUrl: imageUrl, // Pass the image URL
          );
        });
      }
    }
  }

  // Handles both types of search results
  Future<void> _handleSearchTap() async {
    final String? result = await showSearch(
      context: context,
      delegate: PlacesSearchDelegate(),
    );

    if (result != null && result.isNotEmpty) {
      if (result.startsWith("query:")) {
        final query = result.substring(6);
        _performTextSearch(query);
      } else {
        _getPlaceDetails(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            onTap: (_) {
              setState(() {
                _selectedPlace = null;
              });
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(),
                ),
                _buildFilterChips(),
                const Spacer(),
                if (_selectedPlace != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 100.0,
                      left: 16,
                      right: 16,
                    ),
                    child: _buildLocationCard(_selectedPlace!),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentUserLocation,
        backgroundColor: Colors.black,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _handleSearchTap,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
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
              child: Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  'Search name, city, or everything...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
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
            isBlack: true,
            category: 'tune',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Villa', icon: Icons.home, category: 'villa'),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Hotel',
            icon: Icons.hotel,
            category: 'hotel',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Mansion',
            icon: Icons.location_city,
            category: 'mansion',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Apartment',
            icon: Icons.apartment,
            category: 'apartment',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isBlack = false,
    required String category,
  }) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        if (category != 'tune') {
          setState(() {
            _selectedCategory = category;
          });
          _fetchNearbyPlaces(category);
        }
      },
      child: Container(
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
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- UPDATED --- This card now uses the real image URL or a placeholder
  Widget _buildLocationCard(PlaceDetails place) {
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
                      Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.name,
                        style: const TextStyle(
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPlace = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          place.imageUrl ??
                              'https://picsum.photos/400', // Use real URL or placeholder
                          height: 120,
                          fit: BoxFit.cover,
                          // --- NEW --- Add an error builder for the image
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(place.rating.toString()),
                          const SizedBox(width: 8),
                          Text(
                            '${place.totalReviews} Reviews',
                            style: const TextStyle(color: Colors.grey),
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
