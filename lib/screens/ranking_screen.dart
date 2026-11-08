import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<QuerySnapshot> _playersStream;

  @override
  void initState() {
    super.initState();
    _playersStream = _firebaseService.getTopPlayers();
  }

  void _refresh() {
    setState(() {
      _playersStream = _firebaseService.getTopPlayers();
    });
  }

  void _showSetPlayerNameDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String enteredName = '';
        bool isChecking = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void checkAndSave() async {
              final trimmedName = enteredName.trim();
              if (trimmedName.isEmpty) return;

              if (trimmedName.length < 3) {
                setDialogState(() {
                  errorMessage = 'El nombre debe tener al menos 3 caracteres.';
                });
                return;
              }

              if (trimmedName.length > 20) {
                setDialogState(() {
                  errorMessage = 'El nombre no puede superar los 20 caracteres.';
                });
                return;
              }

              if (!RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]').hasMatch(trimmedName)) {
                setDialogState(() {
                  errorMessage = 'El nombre debe contener al menos una letra o número.';
                });
                return;
              }

              setDialogState(() {
                isChecking = true;
                errorMessage = null;
              });

              bool isAvailable = await gameState.isNameAvailable(trimmedName);
              if (!mounted || !dialogCtx.mounted) return;

              if (isAvailable) {
                gameState.setPlayerName(trimmedName);
                _refresh();
                Navigator.of(dialogCtx).pop();
              } else {
                setDialogState(() {
                  isChecking = false;
                  errorMessage = 'Ese nombre ya está en uso. ¡Elige otro!';
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text('Ingresa tu nombre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Elige tu nombre para figurar en el Ranking Global:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 15),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      maxLength: 20,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ _\.-]')),
                      ],
                      decoration: InputDecoration(
                        counterStyle: const TextStyle(color: Colors.white38),
                        hintText: 'Tu nombre (3-20 letras)',
                        hintStyle: const TextStyle(color: Colors.white30),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                        errorText: errorMessage,
                        errorMaxLines: 2,
                      ),
                      onChanged: (val) {
                        enteredName = val;
                        if (errorMessage != null) {
                          setDialogState(() { errorMessage = null; });
                        }
                      },
                      onSubmitted: (val) {
                        if (!isChecking) checkAndSave();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecking ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
                ),
                isChecking
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                        onPressed: checkAndSave,
                        child: const Text('GUARDAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('GLOBAL RANKING', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            tooltip: 'Actualizar ranking',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, _) {
          return Column(
            children: [
              if (gameState.playerName.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.cyanAccent),
                    label: const Text(
                      'Ingresa tu nombre para unirte al Ranking',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showSetPlayerNameDialog(context, gameState),
                  ),
                )
              else 
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Playing as: ${gameState.playerName}',
                    style: const TextStyle(color: Colors.yellowAccent, fontSize: 18),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _playersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      debugPrint('Error cargando ranking: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No pudimos cargar el ranking en este momento. Revisa tu conexión e intenta de nuevo.',
                                style: TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                                onPressed: _refresh,
                                child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No scores yet.', style: TextStyle(color: Colors.white)));
                    }

                    // Traer todos los jugadores con puntaje diferente de cero sin eliminar ninguno por inactividad
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final score = (data['score'] as num?)?.toInt() ?? 0;
                      return score > 0;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text('No scores yet.', style: TextStyle(color: Colors.white)));
                    }

                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'EN VIVO',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: Colors.cyanAccent,
                            backgroundColor: Colors.black,
                            onRefresh: () async {
                              _refresh();
                              await Future.delayed(const Duration(milliseconds: 500));
                            },
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final name = data['playerName'] ?? 'Unknown';
                                final score = data['score'] ?? 0;
                                final isMe = FirebaseAuth.instance.currentUser?.uid == docs[index].id;

                                return ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (index <= 2)
                                        ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400]! : Colors.brown[300]!), 
                                            BlendMode.srcIn
                                          ),
                                          child: Text('👑 ', style: TextStyle(fontSize: index == 0 ? 32 : 22)),
                                        ),
                                      Text(
                                        '#${index + 1}', 
                                        style: TextStyle(
                                          color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[300] : (index == 2 ? Colors.brown[300] : Colors.white)), 
                                          fontSize: 24, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    name, 
                                    style: TextStyle(
                                      color: isMe ? Colors.yellowAccent : Colors.white,
                                      fontSize: 20,
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                                  trailing: Text(
                                    '$score', 
                                    style: const TextStyle(
                                      color: Colors.cyanAccent, 
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
