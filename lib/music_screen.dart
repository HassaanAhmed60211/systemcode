import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key? key}) : super(key: key);

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  TextEditingController searchControllermusic = TextEditingController();
  List<String> musicHistory = [];
  List<String> musicSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData(); // Create an instance

  @override
  void initState() {
    super.initState();
    // Fetch music history when the widget is initialized
    updatemusicHistory('');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 500,
            child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: searchControllermusic,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.bgColors,
                    ),
                    onPressed: () {
                      // Handle the search functionality here
                      final searchTerm = searchControllermusic.text;
                      // You can use the searchTerm to search for musics
                      // and update the musicHistory and musicSuggestions accordingly
                      // For example, you can call a function to fetch music data.
                      print(searchTerm);
                      updatemusicHistory(searchTerm);
                      historyData.storemusicHistory(userId, searchTerm);
                      searchControllermusic.clear();
                    },
                  ),
                ),
              ),
              suggestionsCallback: (pattern) {
                return _getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  searchControllermusic.text = suggestion;
                });
              },
            ),
          ),
          // Display the search results here using the `musicHistory`
          // You can also display the suggestions using `musicSuggestions`
        ],
      ),
    );
  }

  void updatemusicHistory(String searchTerm) async {
    String userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with the actual user ID

    final fetchedmusicHistory = await historyData.fetchmusicHistory(userId);

    setState(() {
      musicHistory = fetchedmusicHistory;
      musicSuggestions =
          fetchedmusicHistory; // Update suggestions based on fetched history
    });
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    // Iterate in reverse order
    for (int i = musicHistory.length - 1; i >= 0; i--) {
      final String music = musicHistory[i];
      if (music.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(music);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Future<List<String>> fetchmusicHistory(String userId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final musicHistoryCollection = userDocRef.collection('music');
      final musicHistoryDocument = musicHistoryCollection.doc(userId);

      final musicHistorySnapshot = await musicHistoryDocument.get();
      if (musicHistorySnapshot.exists) {
        final data = musicHistorySnapshot.data();
        if (data != null && data['musicHistory'] is List) {
          final musicHistory = List<String>.from(data['musicHistory']);
          return musicHistory;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching music history: $e');
      return [];
    }
  }

  Future<void> storemusicHistory(String userId, String music) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final musicHistoryCollection = userDocRef.collection('music');
      final musicHistoryDocument = musicHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

      final existingData = await musicHistoryDocument.get();
      List<String> musicHistory = [];

      if (existingData.exists) {
        final data = existingData.data();
        if (data != null && data['musicHistory'] is List) {
          musicHistory = List<String>.from(data['musicHistory']);
        }
      } else {
        musicHistory = [];
      }

      musicHistory.add(music);

      await musicHistoryDocument.set({'musicHistory': musicHistory});
      print('music history data added successfully');
    } catch (e) {
      print('Error storing music history: $e');
    }
  }
}
