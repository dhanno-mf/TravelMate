import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:intl/intl.dart'; // Package for date formatting

// --- UPDATED ---
// Your Gemini API Key has been added.
const String kGeminiApiKey = "AIzaSyAOHqSb4KGcl0sLnHIdkXvb0M2Ierprpm0";

// Data class to represent a single chat message
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class FullScreenChatbotScreen extends StatefulWidget {
  const FullScreenChatbotScreen({super.key});

  @override
  State<FullScreenChatbotScreen> createState() =>
      _FullScreenChatbotScreenState();
}

class _FullScreenChatbotScreenState extends State<FullScreenChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  // --- NEW --- State to hold user's location
  String _userLocation = "an unknown location";

  @override
  void initState() {
    super.initState();
    // --- NEW --- Fetch location when the chatbot opens
    _getCurrentLocation();
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hi! I'm your Travel Mate. How can I help you plan your next adventure?",
          isUser: false,
        ),
      );
    });
  }

  // --- NEW --- Function to get the user's current location for context
  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      locationData = await location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          if (mounted) {
            setState(() {
              _userLocation = "${placemark.locality}, ${placemark.country}";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Could not get location for chatbot context: $e");
    }
  }

  // --- UPDATED --- This function now sends the entire conversation history
  Future<void> _sendMessageToGemini(String message) async {
    if (kGeminiApiKey == "YOUR_GEMINI_API_KEY") {
      debugPrint("API Key is not set. Cannot send message.");
      setState(() {
        _messages.add(
          ChatMessage(text: "Error: API Key not configured.", isUser: false),
        );
      });
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });

    try {
      final String currentDate = DateFormat('yMMMMd').format(DateTime.now());
      // --- FIXED --- System prompt is now part of the conversation history, not a separate role.
      final String systemPrompt =
          "You are 'Travel Mate', an expert travel assistant. "
          "Your purpose is to help users plan trips, find destinations, suggest itineraries, "
          "and answer travel-related questions. Always be friendly, helpful, and focus "
          "exclusively on travel. Do not answer questions that are not related to travel. "
          "If asked a non-travel question, politely decline and steer the conversation back to travel.\n\n"
          "--- User Context ---\n"
          "User's Name: Anupam\n"
          "Current Location: $_userLocation\n"
          "Current Date: $currentDate\n"
          "--------------------";

      // --- FIXED --- Construct the full conversation history correctly
      final history = _messages.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text},
          ],
        };
      }).toList();

      // Prepend the system prompt to the first user message
      if (history.isNotEmpty && history.first['role'] == 'user') {
        history.insert(0, {
          'role': 'user',
          'parts': [
            {'text': systemPrompt},
          ],
        });
        history.insert(1, {
          'role': 'model',
          'parts': [
            {'text': 'Understood. I am Travel Mate, ready to assist.'},
          ],
        });
      }

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$kGeminiApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // --- FIXED --- Send the correctly formatted history
          'contents': history,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add(ChatMessage(text: text, isUser: false));
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(text: "Error: ${response.body}", isUser: false),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Hero(
        tag: 'chatbot-hero',
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background layers
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade50, Colors.grey.shade300],
                  ),
                ),
              ),
              Opacity(
                opacity: 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/grain.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // UI Content
              SafeArea(
                child: Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildChatMessage(message);
                        },
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    _buildChatInputField(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildChatInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _sendMessageToGemini(text);
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.send, color: Colors.grey.shade600),
            onPressed: () {
              final text = _textController.text;
              if (text.isNotEmpty) {
                _sendMessageToGemini(text);
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
