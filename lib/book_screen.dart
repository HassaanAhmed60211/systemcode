import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({Key? key}) : super(key: key);

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  TextEditingController searchControllerbook = TextEditingController();
  List<String> bookHistory = [];
  List<String> bookSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData(); // Create an instance

  @override
  void initState() {
    super.initState();
    // Fetch book history when the widget is initialized
    updatebookHistory('');
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
                controller: searchControllerbook,
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
                      final searchTerm = searchControllerbook.text;
                      // You can use the searchTerm to search for books
                      // and update the bookHistory and bookSuggestions accordingly
                      // For example, you can call a function to fetch book data.
                      print(searchTerm);
                      updatebookHistory(searchTerm);
                      historyData.storebookHistory(userId, searchTerm);
                      searchControllerbook.clear();
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
                  searchControllerbook.text = suggestion;
                });
              },
            ),
          ),
          // Display the search results here using the `bookHistory`
          // You can also display the suggestions using `bookSuggestions`
        ],
      ),
    );
  }

  void updatebookHistory(String searchTerm) async {
    String userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with the actual user ID

    final fetchedbookHistory = await historyData.fetchbookHistory(userId);

    setState(() {
      bookHistory = fetchedbookHistory;
      bookSuggestions =
          fetchedbookHistory; // Update suggestions based on fetched history
    });
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    // Iterate in reverse order
    for (int i = bookHistory.length - 1; i >= 0; i--) {
      final String book = bookHistory[i];
      if (book.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(book);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Future<List<String>> fetchbookHistory(String userId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final bookHistoryCollection = userDocRef.collection('book');
      final bookHistoryDocument = bookHistoryCollection.doc(userId);

      final bookHistorySnapshot = await bookHistoryDocument.get();
      if (bookHistorySnapshot.exists) {
        final data = bookHistorySnapshot.data();
        if (data != null && data['bookHistory'] is List) {
          final bookHistory = List<String>.from(data['bookHistory']);
          return bookHistory;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching book history: $e');
      return [];
    }
  }

  Future<void> storebookHistory(String userId, String book) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final bookHistoryCollection = userDocRef.collection('book');
      final bookHistoryDocument = bookHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

      final existingData = await bookHistoryDocument.get();
      List<String> bookHistory = [];

      if (existingData.exists) {
        final data = existingData.data();
        if (data != null && data['bookHistory'] is List) {
          bookHistory = List<String>.from(data['bookHistory']);
        }
      } else {
        bookHistory = [];
      }

      bookHistory.add(book);

      await bookHistoryDocument.set({'bookHistory': bookHistory});
      print('book history data added successfully');
    } catch (e) {
      print('Error storing book history: $e');
    }
  }
}
