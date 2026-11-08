import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final RegExp _nombrePermitidoRegex = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ _\.-]{3,20}$');

  static bool esNombreSeguro(String nombre) {
    final limpio = nombre.trim();
    return _nombrePermitidoRegex.hasMatch(limpio) &&
        RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]').hasMatch(limpio);
  }

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

  /// Normaliza el nombre de usuario a minúsculas y sin tildes/acentos
  /// para evitar suplantaciones o nombres duplicados casi idénticos.
  static String normalizeUsername(String name) {
    var result = name.trim().toLowerCase();
    const withDiacritics = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const withoutDiacritics = 'aaaaaeeeeiiiiooooouuuun';
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> submitScore(
    String playerName,
    int score, {
    int? coins,
    List<int>? ownedSkins,
    int? currentSkinIndex,
    List<String>? unlockedAchievements,
  }) async {
    if (!esNombreSeguro(playerName)) return;
    
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
          'normalizedName': normalizeUsername(playerName),
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
          'normalizedName': normalizeUsername(playerName),
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
    if (!esNombreSeguro(playerName)) return false;
    try {
      final currentUser = await ensureSignedIn();
      if (currentUser == null) return false;

      final docRef = _db.collection('leaderboard').doc(currentUser.uid);
      await docRef.delete();
      final data = <String, dynamic>{
        'playerName': playerName,
        'normalizedName': normalizeUsername(playerName),
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
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 20) return false;
    final normalized = normalizeUsername(trimmed);

    try {
      // 1. Consultar por nombre normalizado (Alternativa B: insensibilidad a mayúsculas y tildes)
      final queryNorm = await _db
          .collection('leaderboard')
          .where('normalizedName', isEqualTo: normalized)
          .get();

      final currentUid = _auth.currentUser?.uid;

      if (queryNorm.docs.isEmpty) {
        // Fallback para documentos antiguos que pudieran no tener normalizedName
        final queryLegacy = await _db
            .collection('leaderboard')
            .where('playerName', isEqualTo: trimmed)
            .get();
        if (queryLegacy.docs.isEmpty) {
          return true; // Completamente libre
        }
        if (queryLegacy.docs.length == 1 && currentUid != null) {
          return queryLegacy.docs.first.id == currentUid;
        }
        return false;
      }

      if (queryNorm.docs.length == 1 && currentUid != null) {
        // Si ya existe una vez, verificar si le pertenece al usuario actual
        return queryNorm.docs.first.id == currentUid;
      }

      return false; // Alguien más lo tiene
    } catch (e) {
      debugPrint('Error comprobando disponibilidad de nombre: $e');
      return false;
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
      final normalized = normalizeUsername(name);
      var query = await _db
          .collection('leaderboard')
          .where('normalizedName', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        query = await _db
            .collection('leaderboard')
            .where('playerName', isEqualTo: name.trim())
            .limit(1)
            .get();
      }
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
