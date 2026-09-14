import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitScore(String playerName, int score) async {
    if (playerName.isEmpty) return;
    
    try {
      // Ensure user is signed in anonymously
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      
      final String uid = _auth.currentUser?.uid ?? 'unknown';
      if (uid == 'unknown') return;

      final docRef = _db.collection('leaderboard').doc(uid);
      final docSnap = await docRef.get();
      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      
      if (docSnap.exists) {
        final currentScore = docSnap.data()?['score'] ?? 0;
        await docRef.update({
          'playerName': playerName, // Ensure name is up to date
          'score': score > currentScore ? score : currentScore,
          'timestamp': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt,
        });
      } else {
        await docRef.set({
          'playerName': playerName,
          'score': score,
          'timestamp': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt,
        });
      }
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  Future<bool> isNameAvailable(String name) async {
    try {
      final querySnapshot = await _db
          .collection('leaderboard')
          .where('playerName', isEqualTo: name)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return true; // Name is totally free
      }

      // If the name exists, check if it belongs to the current user
      final currentUid = _auth.currentUser?.uid;
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUid) {
          return false; // Someone else has it
        }
      }
      return true; // Current user owns it
    } catch (e) {
      print('Error checking name availability: $e');
      return false; // Assume unavailable on error to prevent duplicates
    }
  }

  Stream<QuerySnapshot> getTopPlayers() {
    return _db
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(10)
        .snapshots();
  }
}
