import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neon_jump/main.dart' as app;
import 'package:neon_jump/game/neon_jump_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Camera correctly follows player up', (WidgetTester tester) async {
    app.main();
    // Wait for the async main() function (SharedPreferences, Ads, etc) to finish and call runApp()
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Find and tap the PLAY button on main menu
    final playButton = find.text('PLAY');
    expect(playButton, findsOneWidget);
    await tester.tap(playButton);
    await tester.pumpAndSettle();

    // Give it a second to load the game screen
    await tester.pump(const Duration(seconds: 1));

    // Find the Flame Game widget
    final gameWidgetFinder = find.byType(GameWidget<NeonJumpGame>);
    expect(gameWidgetFinder, findsOneWidget);

    final GameWidget<NeonJumpGame> gameWidget = tester.widget(gameWidgetFinder);
    final NeonJumpGame game = gameWidget.game!;

    // Capture initial camera and player positions
    final initialCameraY = game.camera.viewfinder.position.y;
    final initialPlayerY = game.player.position.y;

    // Simulate 3 seconds of gameplay (player jumping up)
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Now check positions after the player has jumped and ascended
    final finalCameraY = game.camera.viewfinder.position.y;
    final finalPlayerY = game.player.position.y;

    // In Flame, smaller Y means moving UP the screen.
    // So the camera Y should be smaller than it started if it followed the player.
    expect(
      finalCameraY < initialCameraY,
      true,
      reason: 'Camera did not move up! Initial Y: $initialCameraY, Final Y: $finalCameraY',
    );

    // Player Y should also be smaller (meaning player ascended)
    expect(
      finalPlayerY < initialPlayerY,
      true,
      reason: 'Player did not move up! Initial Y: $initialPlayerY, Final Y: $finalPlayerY',
    );
    
    // Check if player is contained properly inside the camera view
    // (Player Y should not be smaller than Camera Y - offset)
    double targetCameraY = game.player.position.y - game.size.y * 0.25;
    expect(
      finalCameraY <= targetCameraY + 10, // within a 10px tolerance of lerp
      true,
      reason: 'Camera is not keeping up with the player!',
    );
  });
}
