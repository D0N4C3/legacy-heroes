import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/components/hero_avatar.dart';
import '../../game/legacy_game.dart';
import '../../game/scene_type.dart';
import '../../state/providers.dart';
import '../overlays/heir_selection_overlay.dart';
import '../overlays/home_hud.dart';
import '../overlays/offline_overlay.dart';
import '../overlays/rewards_overlay.dart';

/// The main game screen: a full-screen Flame world with Flutter overlays on
/// top (Visual Plan §2, §10). This is the most important screen — it must feel
/// like a living world, never a dashboard.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final LegacyGame _game = LegacyGame();
  bool _modalBusy = false;

  @override
  void initState() {
    super.initState();
    // Boot the game loop (loads save, applies offline progress, starts ticker).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).init();
    });
  }

  HeroAnim _animFor(SceneType scene) => switch (scene) {
        SceneType.training => HeroAnim.train,
        SceneType.dungeon => HeroAnim.attack,
        SceneType.boss => HeroAnim.attack,
        _ => HeroAnim.idle,
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final scene = ref.watch(currentSceneProvider);

    // Keep the Flame world in sync with game state (idempotent; only swaps the
    // scene when it actually changes).
    final hero = state.hero;
    if (hero != null) {
      _game.sync(
        scene: scene,
        classId: hero.classId,
        anim: _animFor(scene),
        generation: state.generation,
      );
    }

    // Push the Phase 2 combat mini-game's live state (HP, hits, approach)
    // onto the active scene every frame it changes.
    final combat = ref.watch(combatControllerProvider);
    _game.syncCombat(combat);

    // Auto-surface offline report, rewards, and the heir ceremony.
    _wireListeners();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          if (hero == null)
            const Center(
              child: Text('Forging your legacy…',
                  style: TextStyle(color: Color(0xFFEAD7AE), fontSize: 16)),
            )
          else
            const Positioned.fill(child: SafeArea(child: HomeHud())),
        ],
      ),
    );
  }

  void _wireListeners() {
    // One listener watching all three auto-modal triggers; the pump shows them
    // one at a time, in priority order, until none remain.
    ref.listen<(bool, bool, bool)>(
      gameControllerProvider.select(
        (s) => (s.offlineReport != null, s.pendingResult != null, s.awaitingHeir),
      ),
      (_, __) => _pumpModals(),
    );
  }

  /// Surface pending ceremonies sequentially so they never stack.
  Future<void> _pumpModals() async {
    if (_modalBusy) return;
    _modalBusy = true;
    try {
      while (mounted) {
        final s = ref.read(gameControllerProvider);
        if (s.awaitingHeir) {
          if (!mounted) return;
          await showHeirSelection(context, ref, _game);
        } else if (s.offlineReport != null) {
          if (!mounted) return;
          await showOfflineReport(context, ref, _game);
        } else if (s.pendingResult != null) {
          if (!mounted) return;
          await showRewards(context, ref, _game);
        } else {
          break;
        }
      }
    } finally {
      _modalBusy = false;
    }
  }
}
