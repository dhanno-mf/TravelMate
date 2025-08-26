import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Data class to represent trip information
class Trip {
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final int totalDays;

  Trip({
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
  }) : totalDays = endDate.difference(startDate).inDays;
}

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => ItineraryScreenState();
}

class ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // --- UPDATED --- Sample trip data is now dynamic based on the current date
  final List<Trip> _allTrips = [
    // Active Trip
    Trip(
      title: 'Golden Triangle Tour',
      destination: 'Delhi, Agra, Jaipur',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      imageUrl: 'https://picsum.photos/400/301',
    ),
    // Upcoming Trips
    Trip(
      title: 'Kerala Backwaters',
      destination: 'Alleppey, Kerala',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 17)),
      imageUrl: 'https://picsum.photos/400/302',
    ),
    Trip(
      title: 'Himalayan Trek',
      destination: 'Manali, Himachal Pradesh',
      startDate: DateTime.now().add(const Duration(days: 45)),
      endDate: DateTime.now().add(const Duration(days: 53)),
      imageUrl: 'https://picsum.photos/400/303',
    ),
    // Completed Trip
    Trip(
      title: 'Goa Beach Holiday',
      destination: 'Goa, India',
      startDate: DateTime.now().subtract(const Duration(days: 11)),
      endDate: DateTime.now().subtract(const Duration(days: 6)),
      imageUrl: 'https://picsum.photos/400/304',
    ),
  ];

  late List<Trip> _upcomingTrips;
  late List<Trip> _activeTrips;
  late List<Trip> _completedTrips;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);

    // Categorize trips based on the current date
    final now = DateTime.now();
    _upcomingTrips = _allTrips
        .where((trip) => trip.startDate.isAfter(now))
        .toList();
    _activeTrips = _allTrips
        .where(
          (trip) => trip.startDate.isBefore(now) && trip.endDate.isAfter(now),
        )
        .toList();
    _completedTrips = _allTrips
        .where((trip) => trip.endDate.isBefore(now))
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- NEW --- Public method to be called by the parent widget
  void addTrip() {
    debugPrint("Add new trip button tapped!");
    // In the future, this will navigate to a new screen to create a trip
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Trips'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(_upcomingTrips),
          _buildTripList(_activeTrips),
          _buildTripList(_completedTrips),
        ],
      ),
      // --- REMOVED --- The floating action button is now managed by the parent
    );
  }

  Widget _buildTripList(List<Trip> trips) {
    if (trips.isEmpty) {
      return const Center(child: Text('No trips in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(trips[index]);
      },
    );
  }

  Widget _buildTripCard(Trip trip) {
    final formattedStartDate = DateFormat('MMM d, yyyy').format(trip.startDate);
    final formattedEndDate = DateFormat('MMM d, yyyy').format(trip.endDate);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            child: Image.network(
              trip.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.destination,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$formattedStartDate - $formattedEndDate',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${trip.totalDays} Days',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.black),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
