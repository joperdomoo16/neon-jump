import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Garantiza que exista un usuario autenticado (anónimo si no usó Google).
  /// Sin esto, los jugadores que no inician sesión con Google nunca
  /// podían subir su puntaje al ranking.
  Future<User?> ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user != null) return user;
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('Error en inicio de sesión anónimo: $e');
      return null;
    }
  }

  Future<void> submitScore(
    String playerName,
    int score, {
    int? coins,
    List<int>? ownedSkins,
    int? currentSkinIndex,
    List<String>? unlockedAchievements,
  }) async {
    if (playerName.isEmpty) return;
    
    try {
      final currentUser = await ensureSignedIn();
      if (currentUser == null) return;
      
      final String uid = currentUser.uid;

      final docRef = _db.collection('leaderboard').doc(uid);
      final docSnap = await docRef.get();
      // Retención: mientras la base de jugadores crece, no se eliminan registros por inactividad
      // (expiresAt fijado a fecha lejana para que el TTL de Firestore no los borre hasta nuevo aviso).
      final expiresAt = Timestamp.fromDate(DateTime(2099, 12, 31));
      
      if (docSnap.exists) {
        final currentScore = (docSnap.data()?['score'] as num?)?.toInt() ?? 0;
        final updateData = <String, dynamic>{
          'playerName': playerName, // Ensure name is up to date
          'score': score > currentScore ? score : currentScore,
          'timestamp': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt,
        };
        if (coins != null) {
          updateData['coins'] = coins;
        }
        if (ownedSkins != null) {
          updateData['ownedSkins'] = ownedSkins;
        }
        if (currentSkinIndex != null) {
          updateData['currentSkinIndex'] = currentSkinIndex;
        }
        if (unlockedAchievements != null) {
          updateData['unlockedAchievements'] = unlockedAchievements;
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
        if (ownedSkins != null) {
          createData['ownedSkins'] = ownedSkins;
        }
        if (currentSkinIndex != null) {
          createData['currentSkinIndex'] = currentSkinIndex;
        }
        if (unlockedAchievements != null) {
          createData['unlockedAchievements'] = unlockedAchievements;
        }
        await docRef.set(createData);
      }
    } catch (e) {
      debugPrint('Error submitting score/coins/skins/achievements: $e');
    }
  }

  /// Sobrescribe por completo los datos del usuario actual en la nube.
  /// Se usa cuando el jugador elige REEMPLAZAR los datos de su cuenta de Google
  /// por los de la partida actual. Como las reglas no permiten bajar el puntaje
  /// con una actualización, se borra el registro y se crea de nuevo.
  Future<bool> overwriteUserData(
    String playerName,
    int score,
    int coins, {
    List<int>? ownedSkins,
    int? currentSkinIndex,
    List<String>? unlockedAchievements,
  }) async {
    if (playerName.isEmpty) return false;
    try {
      final currentUser = await ensureSignedIn();
      if (currentUser == null) return false;

      final docRef = _db.collection('leaderboard').doc(currentUser.uid);
      await docRef.delete();
      final data = <String, dynamic>{
        'playerName': playerName,
        'score': score,
        'coins': coins,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime(2099, 12, 31)),
      };
      if (ownedSkins != null) data['ownedSkins'] = ownedSkins;
      if (currentSkinIndex != null) data['currentSkinIndex'] = currentSkinIndex;
      if (unlockedAchievements != null) data['unlockedAchievements'] = unlockedAchievements;
      await docRef.set(data);
      return true;
    } catch (e) {
      debugPrint('Error sobrescribiendo datos del usuario: $e');
      return false;
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

  /// Stream en vivo con todos los jugadores cuyo puntaje es mayor a 0 (diferente de cero).
  /// Por defecto no limita la consulta para incluir a todos los jugadores activos.
  Stream<QuerySnapshot> getTopPlayers({int? limit}) {
    Query query = _db
        .collection('leaderboard')
        .where('score', isGreaterThan: 0)
        .orderBy('score', descending: true);
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    return query.snapshots();
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
          // Link anonymous to Google to keep data (same uid => no duplicates)
          return await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // La cuenta de Google ya tiene su propio registro en el ranking.
            // Borramos el registro anónimo para que el jugador no aparezca dos veces.
            // El progreso local se conserva y se resuelve en loginWithGoogle().
            try {
              await _db.collection('leaderboard').doc(currentUser.uid).delete();
            } catch (err) {
              debugPrint('No se pudo borrar el registro anónimo: $err');
            }
          }
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

  Future<Map<String, dynamic>?> getDataByPlayerName(String name) async {
    try {
      final query = await _db
          .collection('leaderboard')
          .where('playerName', isEqualTo: name)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error buscando datos del jugador $name: $e');
      return null;
    }
  }
}
