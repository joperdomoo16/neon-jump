class Achievement {
  final String id;
  final String title;
  final String description;
  final int bonusCoins;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.bonusCoins,
    this.isUnlocked = false,
  });
}
