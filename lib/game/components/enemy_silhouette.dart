import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../art/enemy_art.dart';
import '../art/goblin_sprites.dart';

export '../art/enemy_art.dart' show EnemyType;

/// In-world enemy. Foes with real sprite sheets (currently the Goblin) render
/// those animations; every other type is drawn procedurally by [EnemyArt] so
/// the silhouette and the UI portraits stay in sync. Also carries the combat
/// mini-game's live HP/flash/defeat state (pushed in from
/// `GameScene.applyCombat`). [boss] enlarges the demon for the Demon Gate
/// encounter.
class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required Vector2 position,
    this.type = EnemyType.goblin,
    this.boss = false,
  }) {
    this.position = position;
    priority = 9;
  }

  EnemyType type;
  bool boss;

  /// Current/max HP for the combat HP bar. [maxHealth] of 0 hides the bar
  /// (decorative enemy, outside an active encounter).
  int health = 0;
  int maxHealth = 0;

  /// The engage position the foe walks up to. Scenes set this in layout().
  double homeX = 0;

  double _t = 0;
  double _hitFlash = 0;
  double _defeat = 0;
  bool _walkingIn = false;

  /// Whether the foe is currently striding in (used for a walk wobble).
  bool get isWalkingIn => _walkingIn;

  // ── Sprite-sheet rendering (types with real art) ────────────────────────
  /// Foe types that have hand-drawn sprite sheets instead of code art.
  static const Set<EnemyType> _spriteTypes = {EnemyType.goblin};

  /// On-screen height of the sprite (the 256px frame is scaled to this).
  static const double _spriteRenderSize = 190;

  /// Source sprites face right; flip so the foe faces the hero on the left.
  static const bool _spriteFacesAwayFromHero = true;

  Map<GoblinAnim, SpriteAnimation>? _anims;
  SpriteAnimationTicker? _ticker;
  GoblinAnim? _tickerAnim;
  EnemyType? _loadedType;
  bool _loadingSprites = false;

  bool get _usesSprites => _spriteTypes.contains(type);

  /// Swap in a fresh foe (new type/HP), clearing any in-progress defeat fx.
  void spawn(EnemyType newType, int newHealth, int newMaxHealth) {
    type = newType;
    health = newHealth;
    maxHealth = newMaxHealth;
    _hitFlash = 0;
    _defeat = 0;
    final anims = _anims;
    if (anims != null) {
      _ticker = anims[GoblinAnim.running]?.createTicker();
      _tickerAnim = GoblinAnim.running;
    }
  }

  /// Make the foe stride in from off-screen ([fromX]) to its [homeX].
  void walkIn(double fromX) {
    position.x = fromX;
    _walkingIn = true;
  }

  /// Update HP without resetting the visual state (e.g. after a hit).
  void setHealth(int newHealth) => health = newHealth;

  /// Briefly tint the creature on a landed hit.
  void flashHit() => _hitFlash = 1.0;

  /// One-shot sword-swing animation, played when this foe lands a blow on the
  /// hero. No-op for types without an attack sprite.
  void playAttack() {
    final anims = _anims;
    if (anims == null) return;
    _ticker = anims[GoblinAnim.attack]?.createTicker();
    _tickerAnim = GoblinAnim.attack;
  }

  /// Start the death animation (sprite types) or shrink/fade-out (procedural
  /// fallback) once the foe is defeated.
  void startDefeat() {
    if (_defeat != 0) return;
    _defeat = 0.001;
    final anims = _anims;
    if (anims != null) {
      _ticker = anims[GoblinAnim.dying]?.createTicker();
      _tickerAnim = GoblinAnim.dying;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_hitFlash > 0) _hitFlash = (_hitFlash - dt * 4).clamp(0.0, 1.0);
    if (_defeat > 0) _defeat = (_defeat + dt * 2.5).clamp(0.0, 1.0);
    if (_walkingIn) {
      position.x += (homeX - position.x) * (dt * 3.4).clamp(0.0, 1.0);
      if ((homeX - position.x).abs() < 1.5) {
        position.x = homeX;
        _walkingIn = false;
      }
    }

    if (_usesSprites) {
      if (_anims == null && !_loadingSprites) {
        _ensureSprites();
      } else if (_anims != null) {
        _syncTicker(dt);
      }
    } else if (_anims != null) {
      _anims = null;
      _ticker = null;
      _tickerAnim = null;
      _loadedType = null;
    }
  }

  Future<void> _ensureSprites() async {
    if (_loadedType == type && _anims != null) return;
    if (_loadingSprites) return;
    _loadingSprites = true;
    try {
      final game = findGame();
      if (game == null) return;
      _anims = await GoblinSprites.load(game.images);
      _loadedType = type;
      _ticker = _anims![GoblinAnim.running]?.createTicker();
      _tickerAnim = GoblinAnim.running;
    } finally {
      _loadingSprites = false;
    }
  }

  void _syncTicker(double dt) {
    final anims = _anims!;
    // Hop back to the run loop once a one-shot attack finishes. The death
    // clip is left on its final frame (it fades out via [_defeat]).
    if (_tickerAnim == GoblinAnim.attack && (_ticker?.done() ?? true)) {
      _ticker = anims[GoblinAnim.running]?.createTicker();
      _tickerAnim = GoblinAnim.running;
    }
    _ticker?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final ticker = _ticker;
    if (_usesSprites && _anims != null && ticker != null) {
      final sprite = ticker.getSprite();
      // Fade out over the tail of the death clip (matches
      // [GoblinSprites.defeatDuration]).
      final fade =
          _defeat > 0.6 ? (1 - (_defeat - 0.6) / 0.4).clamp(0.0, 1.0) : 1.0;
      canvas.save();
      if (_spriteFacesAwayFromHero) canvas.scale(-1, 1);
      if (fade < 1.0) {
        canvas.saveLayer(
            null, Paint()..color = Color.fromRGBO(255, 255, 255, fade));
      }
      sprite.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2.all(_spriteRenderSize),
        anchor: GoblinSprites.footAnchor,
        overridePaint: _hitFlash > 0
            ? (Paint()
                ..colorFilter = ColorFilter.mode(
                  Color.fromRGBO(255, 90, 90, _hitFlash.clamp(0.0, 1.0)),
                  BlendMode.srcATop,
                ))
            : null,
      );
      if (fade < 1.0) canvas.restore();
      canvas.restore();
      if (maxHealth > 0 && _defeat == 0 && !_walkingIn) _drawHealthBar(canvas);
      return;
    }

    // Procedural fallback (non-sprite types, and their defeat shrink/fade).
    EnemyArt.draw(canvas, type, _t,
        boss: boss, hitFlash: _hitFlash, defeatProgress: _defeat);
    // Hide the HP bar until the foe has marched into engage range.
    if (maxHealth > 0 && _defeat == 0 && !_walkingIn) _drawHealthBar(canvas);
  }

  void _drawHealthBar(Canvas canvas) {
    const width = 56.0;
    const barHeight = 6.0;
    final y = boss ? -164.0 : -78.0;
    final rect = Rect.fromCenter(center: Offset(0, y), width: width, height: barHeight);
    const radius = Radius.circular(3);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius),
        Paint()..color = const Color(0xFF1A1018));

    final pct = maxHealth == 0 ? 0.0 : (health / maxHealth).clamp(0.0, 1.0);
    if (pct > 0) {
      final fill = Rect.fromLTWH(rect.left, rect.top, width * pct, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), Paint()..color = Palette.hp);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = Palette.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
