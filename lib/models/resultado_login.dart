/// Resultado que devuelve la autenticación y sincronización con Google.
/// Contiene el estado del inicio de sesión y los datos guardados en la nube
/// por si existe un conflicto con la partida actual del celular.
class LoginResult {
  final bool success;
  final bool hasConflict;
  final String? cloudName;
  final int? cloudScore;
  final int? cloudCoins;
  final List<int>? cloudOwnedSkins;
  final int? cloudCurrentSkinIndex;
  final List<String>? cloudAchievements;

  LoginResult({
    required this.success,
    this.hasConflict = false,
    this.cloudName,
    this.cloudScore,
    this.cloudCoins,
    this.cloudOwnedSkins,
    this.cloudCurrentSkinIndex,
    this.cloudAchievements,
  });
}

