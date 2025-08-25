import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Re-use the API Key from the explore screen
import 'explore_screen.dart';

// --- FIXED --- Changed from SearchDelegate<String?> to SearchDelegate<String>
class PlacesSearchDelegate extends SearchDelegate<String> {
  final String sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  // --- UI Customization ---

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
    );
  }

  // --- Actions & Leading Icon ---

  @override
  Widget? buildLeading(BuildContext context) {
    // Back button
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(
          context,
          '',
        ); // Close the search delegate, returning an empty string
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    // Clear button
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
          showSuggestions(context);
        },
      ),
    ];
  }

  // --- API Call to Fetch Suggestions ---

  Future<List<dynamic>> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }
    if (kGoogleApiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
      debugPrint("API Key is not set. Cannot fetch suggestions.");
      return [];
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$kGoogleApiKey&sessiontoken=$sessionToken';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'] as List<dynamic>;
    } else {
      return [];
    }
  }

  // --- Building the Results & Suggestions ---

  // --- UPDATED --- This is called when the user submits their search query
  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      // --- FIXED --- Delay the close call to prevent the build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        close(context, "query:$query");
      });
    }
    // Show a loading indicator while the callback is being scheduled
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: _fetchSuggestions(query),
      builder: (context, snapshot) {
        if (query.isEmpty) {
          return const Center(
            child: Text('Start typing to search for a place.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No places found.'));
        }

        final suggestions = snapshot.data!;

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(suggestion['description']),
              onTap: () {
                // When a suggestion is tapped, close the search and return the placeId
                close(context, suggestion['place_id']);
              },
            );
          },
        );
      },
    );
  }
}
