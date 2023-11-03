import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryData {
  Future<List<String>> fetchMovieHistory(String userId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

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

  Future<void> storeMovieHistory(
      String userId, List<String> movieHistory) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(
          userId); // Replace 'user doc id' with the actual user document ID

      await movieHistoryDocument.set({'movieHistory': movieHistory});
      print('Movie history data added successfully');
    } catch (e) {
      print('Error storing movie history: $e');
    }
  }
}
