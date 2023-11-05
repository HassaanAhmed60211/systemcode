import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
  final HistoryData historyData = HistoryData();
  late Stream<List<String>> movieHistoryStream;
  String? searchError;

  @override
  void initState() {
    super.initState();
    movieHistoryStream = historyData.fetchMovieHistoryStream(userId);
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
                  labelText: searchError,
                  labelStyle: TextStyle(
                      color: Colors.red[500],
                      fontWeight: FontWeight.w300,
                      fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.bgColors,
                    ),
                    onPressed: () {
                      final searchTerm = searchControllermovie.text;
                      if (searchTerm.isEmpty) {
                        setState(() {
                          searchError = 'Field is empty';
                        });
                        Timer(const Duration(seconds: 1), () {
                          searchError = null;
                          setState(() {});
                        });
                      } else {
                        // Clear the error message if it was previously set
                        setState(() {
                          searchError = null;
                        });
                        print(searchTerm);
                        historyData.storeMovieHistory(userId, searchTerm);
                        searchControllermovie.clear();
                      }
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
          StreamBuilder<List<String>>(
            stream: movieHistoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                movieHistory = snapshot.data ?? [];
                return Container();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

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
  Stream<List<String>> fetchMovieHistoryStream(String userId) {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');

      return movieHistoryCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['movieHistory'] is List) {
            final movieHistoryList =
                List<Map<String, dynamic>>.from(data['movieHistory']);
            final movies = movieHistoryList
                .map((movieData) => movieData['movie'].toString())
                .toList();
            return movies;
          }
        }
        return [];
      });
    } catch (e) {
      print('Error fetching movie history: $e');
      return Stream.value([]);
    }
  }

  Future<void> storeMovieHistory(String userId, String movie) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(userId);

      // Get the current timestamp
      final Timestamp timestamp = Timestamp.now();

      // Create a map with the movie and timestamp
      final Map<String, dynamic> movieData = {
        'movie': movie,
        'timestamp': timestamp,
      };

      // Add this map to the movie history
      await movieHistoryDocument.set({
        'movieHistory': FieldValue.arrayUnion([movieData])
      }, SetOptions(merge: true));
      print('Movie history data added successfully');
    } catch (e) {
      print('Error storing movie history: $e');
    }
  }
}
