import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({Key? key}) : super(key: key);

  @override
  _MovieScreenState createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  TextEditingController searchControllermovie = TextEditingController();
  List<String> movieHistory = [];
  List<String> movieSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData(); // Create an instance

  @override
  void initState() {
    super.initState();
    // Fetch movie history when the widget is initialized
    updateMovieHistory('');
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
                controller: searchControllermovie,
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
                      final searchTerm = searchControllermovie.text;
                      // You can use the searchTerm to search for movies
                      // and update the movieHistory and movieSuggestions accordingly
                      // For example, you can call a function to fetch movie data.
                      print(searchTerm);
                      updateMovieHistory(searchTerm);
                      historyData.storeMovieHistory(userId, searchTerm);
                      searchControllermovie.clear();
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
                  searchControllermovie.text = suggestion;
                });
              },
            ),
          ),
          // Display the search results here using the `movieHistory`
          // You can also display the suggestions using `movieSuggestions`
        ],
      ),
    );
  }

  void updateMovieHistory(String searchTerm) async {
    String userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with the actual user ID

    final fetchedMovieHistory = await historyData.fetchMovieHistory(userId);

    setState(() {
      movieHistory = fetchedMovieHistory;
      movieSuggestions =
          fetchedMovieHistory; // Update suggestions based on fetched history
    });
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    // Iterate in reverse order
    for (int i = movieHistory.length - 1; i >= 0; i--) {
      final String movie = movieHistory[i];
      if (movie.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(movie);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Future<List<String>> fetchMovieHistory(String userId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(userId);

      final movieHistorySnapshot = await movieHistoryDocument.get();
      if (movieHistorySnapshot.exists) {
        final data = movieHistorySnapshot.data();
        if (data != null && data['movieHistory'] is List) {
          final movieHistory = List<String>.from(data['movieHistory']);
          return movieHistory;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movie history: $e');
      return [];
    }
  }

  Future<void> storeMovieHistory(String userId, String movie) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

      final existingData = await movieHistoryDocument.get();
      List<String> movieHistory = [];

      if (existingData.exists) {
        final data = existingData.data();
        if (data != null && data['movieHistory'] is List) {
          movieHistory = List<String>.from(data['movieHistory']);
        }
      } else {
        movieHistory = [];
      }

      movieHistory.add(movie);

      await movieHistoryDocument.set({'movieHistory': movieHistory});
      print('Movie history data added successfully');
    } catch (e) {
      print('Error storing movie history: $e');
    }
  }
}
