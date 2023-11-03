import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FashionScreen extends StatefulWidget {
  const FashionScreen({Key? key}) : super(key: key);

  @override
  _FashionScreenState createState() => _FashionScreenState();
}

class _FashionScreenState extends State<FashionScreen> {
  TextEditingController searchControllerfashion = TextEditingController();
  List<String> fashionHistory = [];
  List<String> fashionSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData(); // Create an instance

  @override
  void initState() {
    super.initState();
    // Fetch fashion history when the widget is initialized
    updatefashionHistory('');
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
                controller: searchControllerfashion,
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
                      final searchTerm = searchControllerfashion.text;
                      // You can use the searchTerm to search for fashions
                      // and update the fashionHistory and fashionSuggestions accordingly
                      // For example, you can call a function to fetch fashion data.
                      print(searchTerm);
                      updatefashionHistory(searchTerm);
                      historyData.storefashionHistory(userId, searchTerm);
                      searchControllerfashion.clear();
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
                  searchControllerfashion.text = suggestion;
                });
              },
            ),
          ),
          // Display the search results here using the `fashionHistory`
          // You can also display the suggestions using `fashionSuggestions`
        ],
      ),
    );
  }

  void updatefashionHistory(String searchTerm) async {
    String userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with the actual user ID

    final fetchedfashionHistory = await historyData.fetchfashionHistory(userId);

    setState(() {
      fashionHistory = fetchedfashionHistory;
      fashionSuggestions =
          fetchedfashionHistory; // Update suggestions based on fetched history
    });
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    // Iterate in reverse order
    for (int i = fashionHistory.length - 1; i >= 0; i--) {
      final String fashion = fashionHistory[i];
      if (fashion.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(fashion);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Future<List<String>> fetchfashionHistory(String userId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final fashionHistoryCollection = userDocRef.collection('fashion');
      final fashionHistoryDocument = fashionHistoryCollection.doc(userId);

      final fashionHistorySnapshot = await fashionHistoryDocument.get();
      if (fashionHistorySnapshot.exists) {
        final data = fashionHistorySnapshot.data();
        if (data != null && data['fashionHistory'] is List) {
          final fashionHistory = List<String>.from(data['fashionHistory']);
          return fashionHistory;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching fashion history: $e');
      return [];
    }
  }

  Future<void> storefashionHistory(String userId, String fashion) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final fashionHistoryCollection = userDocRef.collection('fashion');
      final fashionHistoryDocument = fashionHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

      final existingData = await fashionHistoryDocument.get();
      List<String> fashionHistory = [];

      if (existingData.exists) {
        final data = existingData.data();
        if (data != null && data['fashionHistory'] is List) {
          fashionHistory = List<String>.from(data['fashionHistory']);
        }
      } else {
        fashionHistory = [];
      }

      fashionHistory.add(fashion);

      await fashionHistoryDocument.set({'fashionHistory': fashionHistory});
      print('fashion history data added successfully');
    } catch (e) {
      print('Error storing fashion history: $e');
    }
  }
}
