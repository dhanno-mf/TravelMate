import 'package:flutter/material.dart';
import 'full_screen_chatbot.dart'; // Import the new full-screen page

class ChatbotScreen extends StatelessWidget {
  // --- NEW --- Callback to close the chatbot
  final VoidCallback onClose;

  const ChatbotScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(
        0.5,
      ), // Semi-transparent background
      // --- UPDATED --- The bottom navigation bar now holds the close button
      bottomNavigationBar: _buildCloseButton(context),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          // --- UPDATED --- Adjusted dimensions and margins
          height: MediaQuery.of(context).size.height * 0.65,
          margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
          // --- UPDATED --- Using a Stack to layer the new background
          child: Hero(
            tag: 'chatbot-hero', // Unique tag for the animation
            child: Material(
              // Material widget is needed for Hero animations
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: The Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey.shade50, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  // Layer 2: The Grain Texture
                  Opacity(
                    opacity: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('assets/grain.jpg'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  // Layer 3: The UI Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flash_on, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Assistant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            // Fullscreen button is now functional
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FullScreenChatbotScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Main prompt text
                        const Text(
                          'Ready to dive into some hotel options or maybe an itinerary?',
                          style: TextStyle(fontSize: 24, color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        // Suggestion chips
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: [
                            _buildSuggestionChip('Hotel options'),
                            _buildSuggestionChip('Itinerary'),
                            _buildSuggestionChip('Things to do'),
                          ],
                        ),
                        const Spacer(),
                        // --- NEW --- Input buttons restored at the bottom
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_alt_outlined,
                                color: Colors.black,
                              ),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED --- Widget for the bottom close button
  Widget _buildCloseButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        bottom: 30.0,
      ), // Positioned closer to the bottom
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }
}
