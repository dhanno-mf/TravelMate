import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSectionTitle('Popular Attractions'),
              const SizedBox(height: 16),
              _buildPopularAttractions(),
              const SizedBox(height: 24),
              _buildSectionTitle('Travel Categories'),
              const SizedBox(height: 16),
              _buildTravelCategories(),
              const SizedBox(height: 24),
              _buildSectionTitle('Recommendations for you', showArrow: true),
              const SizedBox(height: 16),
              _buildRecommendations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Column(
          children: [
            Text(
              'Location',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search destinations',
        hintStyle: const TextStyle(color: Colors.white),
        contentPadding: EdgeInsetsDirectional.only(start: 16.0, end: 16.0),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        suffixIcon: const Icon(Icons.filter_list, color: Colors.white),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showArrow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (showArrow) const Icon(Icons.arrow_forward, color: Colors.black),
      ],
    );
  }

  Widget _buildPopularAttractions() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAttractionCard(
            'https://picsum.photos/200',
            'Explore',
            'Eiffel Tower',
            'September 15, 2023',
          ),
          const SizedBox(width: 16),
          _buildAttractionCard(
            'https://picsum.photos/160',
            'Museum',
            'Louvre',
            'October 1, 2023',
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionCard(
    String imageUrl,
    String tag,
    String title,
    String date,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.favorite_border,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCategoryIcon(Icons.museum, 'Attraction'),
        _buildCategoryIcon(Icons.wine_bar, 'Hidden'),
        _buildCategoryIcon(Icons.brush, 'Local'),
        _buildCategoryIcon(Icons.camera_alt, 'Guided'),
        _buildCategoryIcon(Icons.mic, 'Nature'),
      ],
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }

  Widget _buildRecommendations() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAttractionCard(
            'https://picsum.photos/160',
            'Getaway',
            'Weekend Trip',
            '',
          ),
          const SizedBox(width: 16),
          _buildAttractionCard(
            'https://picsum.photos/160',
            'Restaurant',
            'Local Cuisine',
            '',
          ),
        ],
      ),
    );
  }
}
