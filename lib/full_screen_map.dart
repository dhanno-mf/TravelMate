import 'package:flutter/material.dart';

class FullScreenMapScreen extends StatelessWidget {
  const FullScreenMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites on Map'),
        backgroundColor: const Color(0xFF1B202D),
      ),
      body: Container(
        color: Colors.blueGrey[900],
        child: Center(
          child: Image.network(
            'https://placehold.co/800x1200/2C3246/FFFFFF?text=Full+Screen+Map',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Map could not be loaded',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
