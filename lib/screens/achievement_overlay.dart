import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../services/game_state.dart';

class AchievementOverlay extends StatefulWidget {
  const AchievementOverlay({super.key});

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Achievement? _currentAchievement;
  final List<Achievement> _queue = [];
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.2), // slightly down from top
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      gameState.onAchievementUnlocked = _handleAchievementUnlocked;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAchievementUnlocked(Achievement achievement) {
    if (mounted) {
      setState(() {
        _queue.add(achievement);
      });
      _showNext();
    }
  }

  void _showNext() async {
    if (_isShowing || _queue.isEmpty) return;
    _isShowing = true;

    setState(() {
      _currentAchievement = _queue.removeAt(0);
    });

    await _controller.forward();
    await Future.delayed(const Duration(seconds: 3));
    await _controller.reverse();
    
    _isShowing = false;
    _showNext(); // process next in queue if any
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAchievement == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.amberAccent, blurRadius: 10, spreadRadius: 1)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOGRO DESBLOQUEADO',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      _currentAchievement!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${_currentAchievement!.bonusCoins} Monedas',
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
