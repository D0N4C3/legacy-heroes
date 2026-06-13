import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/services/catalog_service.dart';
import '../../features/family/domain/ancestor.dart';
import '../../features/hero/domain/hero.dart';
import '../../state/providers.dart';
import '../widgets/hero_portrait.dart';
import '../widgets/trait_seal.dart';

/// The **Hall of Ancestors** (plan §3C / Visual Plan signature feature) — the
/// emotional heart of the game. Instead of a database list, the dynasty is a
/// single glowing bloodline: the living head of the family crowned at the top,
/// every forebear descending beneath as a golden memorial portrait strung along
/// a luminous vine. This is meant to be a marketing screenshot.
class FamilyTreeScreen extends ConsumerWidget {
  const FamilyTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final hero = state.hero!;
    final ancestors = [...state.familyTree]
      ..sort((a, b) => b.generation.compareTo(a.generation));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241A2E), Color(0xFF3A2A1C), Color(0xFF140D08)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Palette.goldLight),
          title: const Text('Hall of Ancestors',
              style: TextStyle(
                  color: Palette.goldLight,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _MoteLayer()),
            ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 36),
              children: [
                _DynastyCrest(
                    generation: hero.generation, ancestors: ancestors.length),
                const SizedBox(height: 8),
                // The living head of the family.
                _BloodlineNode(
                  infoOnLeft: false,
                  drawTopVine: false,
                  portrait: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Crown(),
                      const SizedBox(height: 2),
                      _PulseRing(
                        child: HeroPortrait(
                            classId: hero.classId, size: 92, highlighted: true),
                      ),
                    ],
                  ),
                  info: _CurrentInfo(hero: hero),
                ),
                // Every forebear, newest first, descending the vine.
                ...List.generate(ancestors.length, (i) {
                  final a = ancestors[i];
                  return _BloodlineNode(
                    infoOnLeft: i.isEven,
                    drawBottomVine: i != ancestors.length - 1,
                    portrait:
                        HeroPortrait(classId: a.classId, size: 72, memorial: true),
                    info: _AncestorInfo(record: a),
                  );
                }),
                _Roots(empty: ancestors.isEmpty, firstName: hero.name.split(' ').first),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── The bloodline node: a portrait bead on a glowing central vine ───────────
class _BloodlineNode extends StatelessWidget {
  const _BloodlineNode({
    required this.portrait,
    required this.info,
    required this.infoOnLeft,
    this.drawTopVine = true,
    this.drawBottomVine = true,
    this.nodeWidth = 104,
  });

  final Widget portrait;
  final Widget info;
  final bool infoOnLeft;
  final bool drawTopVine;
  final bool drawBottomVine;
  final double nodeWidth;

  @override
  Widget build(BuildContext context) {
    final card = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: info,
    );

    // The Stack sizes to the content Row / portrait (no IntrinsicHeight, so a
    // Wrap of trait seals inside the card is safe); the vine then fills that
    // full height so consecutive nodes connect into one continuous bloodline.
    return Stack(
      alignment: Alignment.center,
      children: [
        // Luminous vine running the full height of the node, centered.
        Positioned.fill(
          child: Center(
            child: Container(
              width: 5,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Palette.gold.withValues(alpha: drawTopVine ? 0.55 : 0.0),
                    Palette.goldLight.withValues(alpha: 0.85),
                    Palette.gold.withValues(alpha: drawBottomVine ? 0.55 : 0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        // Content defines the node's height; the node column stays centered.
        Row(
          children: [
            Expanded(
              child: infoOnLeft
                  ? Align(alignment: Alignment.centerRight, child: card)
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: nodeWidth),
            Expanded(
              child: !infoOnLeft
                  ? Align(alignment: Alignment.centerLeft, child: card)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        portrait,
      ],
    );
  }
}

// ── Info panels ─────────────────────────────────────────────────────────────
class _CurrentInfo extends StatelessWidget {
  const _CurrentInfo({required this.hero});
  final HeroData hero;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: Palette.goldLight,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVING HEAD OF THE BLOODLINE',
              style: TextStyle(
                  color: Palette.goldLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(hero.name,
              style: const TextStyle(
                  color: Palette.parchment,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
          Text(
              'Generation ${hero.generation} · ${hero.classData.name} · Lv ${hero.level} · Age ${hero.age}',
              style: TextStyle(
                  color: Palette.parchment.withValues(alpha: 0.8), fontSize: 11)),
          if (hero.traitIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: hero.traitIds.map((t) => TraitSeal(traitId: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AncestorInfo extends StatelessWidget {
  const _AncestorInfo({required this.record});
  final AncestorRecord record;

  @override
  Widget build(BuildContext context) {
    final cls = Catalog.instance.classOf(record.classId);
    return _Panel(
      borderColor: Palette.gold.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(record.name,
                    style: const TextStyle(
                        color: Palette.parchment,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
              const SizedBox(width: 4),
              Icon(record.retired ? Icons.self_improvement : Icons.local_florist,
                  size: 14, color: Palette.gold),
            ],
          ),
          Text('Gen ${record.generation} · ${cls.name} · Lv ${record.level}',
              style: TextStyle(
                  color: Palette.parchment.withValues(alpha: 0.75), fontSize: 10)),
          Text('${record.lifespan} · ${record.causeOfEnd}',
              style: TextStyle(
                  color: Palette.parchment.withValues(alpha: 0.55), fontSize: 10)),
          const SizedBox(height: 3),
          Text('“${record.biggestAchievement}”',
              style: const TextStyle(
                  color: Palette.goldLight,
                  fontStyle: FontStyle.italic,
                  fontSize: 11)),
          if (record.heirloomName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: Palette.goldLight),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('Passed down: ${record.heirloomName}',
                        style: const TextStyle(
                            color: Palette.goldLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 10)),
                  ),
                ],
              ),
            ),
          if (record.traitIds.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  record.traitIds.map((t) => TraitSeal(traitId: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.borderColor, this.glow = false});
  final Widget child;
  final Color borderColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Palette.woodDark.withValues(alpha: 0.92),
          Palette.wood.withValues(alpha: 0.78),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: glow ? 2 : 1.5),
        boxShadow: glow
            ? [BoxShadow(color: Palette.goldLight.withValues(alpha: 0.25), blurRadius: 14)]
            : null,
      ),
      child: child,
    );
  }
}

// ── Header crest + roots ────────────────────────────────────────────────────
class _DynastyCrest extends StatelessWidget {
  const _DynastyCrest({required this.generation, required this.ancestors});
  final int generation;
  final int ancestors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.park, color: Palette.gold, size: 30),
        const SizedBox(height: 4),
        Text('A bloodline $generation generations strong',
            style: const TextStyle(
                color: Palette.parchment, fontWeight: FontWeight.w800, fontSize: 13)),
        Text(
            ancestors == 0
                ? 'The legacy is only beginning'
                : '$ancestors ${ancestors == 1 ? 'ancestor watches' : 'ancestors watch'} over the family',
            style: TextStyle(
                color: Palette.parchment.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}

class _Roots extends StatelessWidget {
  const _Roots({required this.empty, required this.firstName});
  final bool empty;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Icon(Icons.account_balance, color: Palette.gold.withValues(alpha: 0.7), size: 22),
          const SizedBox(height: 4),
          Text(
            empty
                ? 'Your dynasty begins here.\nOne day $firstName will be\nremembered on this vine.'
                : 'The roots of the family run deep.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Palette.parchment.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── A small gold crown for the living head ──────────────────────────────────
class _Crown extends StatelessWidget {
  const _Crown();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.workspace_premium, color: Palette.goldLight, size: 22);
}

// ── A breathing glow ring around the living hero ────────────────────────────
class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.child});
  final Widget child;
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final pulse = 0.5 + 0.5 * sin(_c.value * 2 * pi);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Palette.goldLight.withValues(alpha: 0.25 + 0.35 * pulse),
                blurRadius: 16 + 12 * pulse,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── Drifting ancestral motes behind the bloodline ───────────────────────────
class _MoteLayer extends StatefulWidget {
  const _MoteLayer();
  @override
  State<_MoteLayer> createState() => _MoteLayerState();
}

class _MoteLayerState extends State<_MoteLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) =>
          CustomPaint(painter: _MotePainter(_c.value), size: Size.infinite),
    );
  }
}

class _MotePainter extends CustomPainter {
  _MotePainter(this.t);
  final double t;

  static final _rng = Random(11);
  static final List<Offset> _seeds =
      List.generate(28, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final y = (s.dy - t * 0.25 + i * 0.013) % 1.0;
      final yy = (1 - y) * size.height;
      final a = 0.12 + 0.22 * (0.5 + 0.5 * sin(t * 2 * pi + i));
      p.color = const Color(0xFFFFE9A8).withValues(alpha: a);
      canvas.drawCircle(Offset(s.dx * size.width, yy), 1.4 + (i % 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter old) => old.t != t;
}
