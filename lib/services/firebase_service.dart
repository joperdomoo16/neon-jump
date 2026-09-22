import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitScore(String playerName, int score, {int? coins}) async {
    if (playerName.isEmpty) return;
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return; // Do not submit if not logged in
      
      // Ensure only Google-linked accounts can upload to the leaderboard
      bool isGoogleLinked = currentUser.providerData.any((p) => p.providerId == 'google.com');
      if (!isGoogleLinked) return;
      
      final String uid = currentUser.uid;

      final docRef = _db.collection('leaderboard').doc(uid);
      final docSnap = await docRef.get();
      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      
      if (docSnap.exists) {
        final currentScore = docSnap.data()?['score'] ?? 0;
        final updateData = <String, dynamic>{
          'playerName': playerName, // Ensure name is up to date
          'score': score > currentScore ? score : currentScore,
          'timestamp': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt,
        };
        if (coins != null) {
          updateData['coins'] = coins;
        }
        await docRef.update(updateData);
      } else {
        final createData = <String, dynamic>{
          'playerName': playerName,
          'score': score,
          'timestamp': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt,
        };
        if (coins != null) {
          createData['coins'] = coins;
        }
        await docRef.set(createData);
      }
    } catch (e) {
      debugPrint('Error submitting score/coins: $e');
    }
  }

  Future<bool> isNameAvailable(String name) async {
    try {
      final query = _db.collection('leaderboard').where('playerName', isEqualTo: name);
      final AggregateQuerySnapshot snapshot = await query.count().get();

      if (snapshot.count == 0) {
        return true; // Name is totally free
      }

      if (snapshot.count == 1) {
        // If the name exists once, check if it belongs to the current user
        final currentUid = _auth.currentUser?.uid;
        if (currentUid != null) {
          final doc = await _db.collection('leaderboard').doc(currentUid).get();
          if (doc.exists && doc.data()?['playerName'] == name) {
            return true; // Current user owns it
          }
        }
      }
      
      return false; // Someone else has it or there are multiple (which shouldn't happen)
    } catch (e) {
      debugPrint('Error checking name availability: $e');
      return false; // Assume unavailable on error to prevent duplicates
    }
  }

  Stream<QuerySnapshot> getTopPlayers({int limit = 50}) {
    return _db
        .collection('leaderboard')
        .where('score', isGreaterThan: 0)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final User? currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          // Link anonymous to Google to keep data
          return await currentUser.linkWithCredential(credential);
        } catch (e) {
          // If already linked or error, just sign in
          return await _auth.signInWithCredential(credential);
        }
      } else {
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('leaderboard').doc(uid).get();
    return doc.data();
  }
}
