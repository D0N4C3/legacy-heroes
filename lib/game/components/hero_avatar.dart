import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../art/hero_art.dart';
import '../art/mage_sprites.dart';

// Re-export so existing imports of this file keep resolving HeroAnim.
export '../art/hero_art.dart' show HeroAnim;

/// In-world animated hero. Classes that ship real sprite sheets (currently the
/// Mage) render those animations; every other class is drawn procedurally by
/// [HeroArt] so the avatar and the UI portraits stay in sync. Also carries the
/// combat mini-game's live HP/flash/pulse state and a smoothed "run forward"
/// target X, pushed in from `GameScene.applyCombat`.
class HeroAvatar extends PositionComponent {
  HeroAvatar({
    required Vector2 position,
    required this.classId,
    this.anim = HeroAnim.idle,
    double scale = 1.0,
  }) : _scale = scale {
    this.position = position;
    priority = 10;
  }

  String classId;
  HeroAnim anim;
  final double _scale;

  double _t = 0;
  double _blink = 0;
  double _nextBlink = 2.5;
  final _rng = Random();

  /// Current/max HP for the combat HP bar. [maxHealth] of 0 hides the bar
  /// (decorative hero, outside an active encounter).
  int health = 0;
  int maxHealth = 0;

  double _hitFlash = 0;
  double _attackPulse = 0;

  /// World-space X to smoothly drift toward (e.g. "run forward" to engage a
  /// foe). Null means stay put.
  double? targetX;

  // ── Sprite-sheet rendering (classes with real art) ──────────────────────
  /// Classes that have hand-drawn sprite sheets instead of code art.
  static const Set<String> _spriteClasses = {'mage'};

  /// On-screen height of the sprite (the 256px frame is scaled to this).
  static const double _spriteRenderSize = 230;

  /// Source sprites face left; flip so the hero faces the foes on the right.
  static const bool _spriteFacesRight = true;

  Map<HeroAnim, SpriteAnimation>? _anims;
  SpriteAnimationTicker? _ticker;
  HeroAnim? _tickerAnim;
  String? _loadedClass;
  bool _loadingSprites = false;

  bool get _usesSprites => _spriteClasses.contains(classId);

  bool get _isBlinking => _blink > _nextBlink;

  /// Briefly tint the hero on taking a counter-hit.
  void flashHit() => _hitFlash = 1.0;

  /// One-shot forward attack swing.
  void pulseAttack() => _attackPulse = 1.0;

  @override
  Future<void> onLoad() async {
    await _ensureSprites();
  }

  Future<void> _ensureSprites() async {
    if (!_usesSprites) {
      _anims = null;
      _ticker = null;
      _loadedClass = null;
      return;
    }
    if (_loadedClass == classId && _anims != null) return;
    if (_loadingSprites) return;
    _loadingSprites = true;
    try {
      final game = findGame() as FlameGame?;
      if (game == null) return;
      _anims = await MageSprites.load(game.images);
      _loadedClass = classId;
      _ticker = null;
      _tickerAnim = null;
    } finally {
      _loadingSprites = false;
    }
  }

  void _syncTicker(double dt) {
    final anims = _anims;
    if (anims == null) return;
    if (_tickerAnim != anim || _ticker == null) {
      _ticker = anims[anim]?.createTicker();
      _tickerAnim = anim;
    }
    _ticker?.update(dt);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _blink += dt;
    if (_blink > _nextBlink + 0.12) {
      _blink = 0;
      _nextBlink = 2 + _rng.nextDouble() * 3;
    }
    if (_hitFlash > 0) _hitFlash = (_hitFlash - dt * 4).clamp(0.0, 1.0);
    if (_attackPulse > 0) _attackPulse = (_attackPulse - dt * 6).clamp(0.0, 1.0);

    final tx = targetX;
    if (tx != null) {
      position.x += (tx - position.x) * min(1.0, dt * 6);
    }

    // Keep sprite state in step with the current class & animation.
    if (_usesSprites) {
      if (_anims == null && !_loadingSprites) {
        _ensureSprites();
      } else {
        _syncTicker(dt);
      }
    } else if (_anims != null) {
      _anims = null;
      _ticker = null;
      _loadedClass = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final ticker = _ticker;
    if (_anims != null && ticker != null) {
      final sprite = ticker.getSprite();
      final s = _spriteRenderSize * _scale;
      canvas.save();
      if (_spriteFacesRight) canvas.scale(-1, 1); // mirror to face the foe
      sprite.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2.all(s),
        anchor: MageSprites.footAnchor,
        overridePaint: _hitFlash > 0
            ? (Paint()
              ..colorFilter = ColorFilter.mode(
                  Color.fromRGBO(255, 80, 80, _hitFlash.clamp(0.0, 1.0)),
                  BlendMode.srcATop))
            : null,
      );
      canvas.restore();
      if (maxHealth > 0) _drawHealthBar(canvas, -150);
      return;
    }

    // Procedural fallback (all non-sprite classes).
    canvas.save();
    canvas.scale(_scale);
    HeroArt.drawBody(
      canvas,
      classId: classId,
      t: _t,
      anim: anim,
      blinking: _isBlinking,
      attackPulse: _attackPulse,
      hitFlash: _hitFlash,
    );
    canvas.restore();
    if (maxHealth > 0) _drawHealthBar(canvas, -98);
  }

  void _drawHealthBar(Canvas canvas, double topY) {
    const width = 60.0;
    const barHeight = 6.0;
    final rect = Rect.fromLTWH(-width / 2, topY - barHeight / 2, width, barHeight);
    const radius = Radius.circular(3);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius),
        Paint()..color = const Color(0xFF1A1018));

    final pct = maxHealth == 0 ? 0.0 : (health / maxHealth).clamp(0.0, 1.0);
    if (pct > 0) {
      final fill = Rect.fromLTWH(rect.left, rect.top, width * pct, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), Paint()..color = Palette.xp);
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
