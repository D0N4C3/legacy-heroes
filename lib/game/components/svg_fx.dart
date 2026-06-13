import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Loads SVG assets once into [PictureInfo]s so Flame can draw vector effects
/// directly onto its canvas (Flame is pure-canvas, so we render the SVG's
/// recorded picture rather than the `SvgPicture` widget).
///
/// Everything here is best-effort: components that use these helpers always
/// keep a code-drawn fallback, so a missing/late asset never breaks rendering.
class SvgFx {
  SvgFx._();

  static final Map<String, PictureInfo> _cache = {};
  static final Set<String> _loading = {};

  /// Decode and cache [asset] (idempotent; safe to call repeatedly).
  static Future<void> preload(String asset) async {
    if (_cache.containsKey(asset) || _loading.contains(asset)) return;
    _loading.add(asset);
    try {
      _cache[asset] = await vg.loadPicture(SvgAssetLoader(asset), null);
    } catch (_) {
      // Leave it uncached; callers fall back to code-drawn art.
    } finally {
      _loading.remove(asset);
    }
  }

  /// Draw [asset] centered on the current origin at [renderSize] px, optionally
  /// faded to [opacity]. Returns false if the asset wasn't ready (caller should
  /// draw its fallback instead).
  static bool draw(ui.Canvas canvas, String asset, double renderSize,
      {double opacity = 1.0}) {
    final pic = _cache[asset];
    if (pic == null) return false;
    final sz = pic.size;
    if (sz.width <= 0 || sz.height <= 0) return false;

    final faded = opacity < 1.0;
    if (faded) {
      canvas.saveLayer(
        null,
        ui.Paint()
          ..color = ui.Color.fromRGBO(
              255, 255, 255, opacity.clamp(0.0, 1.0).toDouble()),
      );
    }
    canvas.save();
    canvas.translate(-renderSize / 2, -renderSize / 2);
    canvas.scale(renderSize / sz.width, renderSize / sz.height);
    canvas.drawPicture(pic.picture);
    canvas.restore();
    if (faded) canvas.restore();
    return true;
  }
}
