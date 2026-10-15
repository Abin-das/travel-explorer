import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/geography.dart';

/// Procedurally drawn landscape illustration used as artwork when no photo
/// is available. Works fully offline and is deterministic per [seed], so a
/// place always gets the same picture.
class SceneArt extends StatelessWidget {
  const SceneArt({super.key, required this.theme, required this.seed});

  final SceneTheme theme;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(painter: _ScenePainter(theme, _hash(seed), dark), size: Size.infinite),
    );
  }

  static int _hash(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }
}

class _Pal {
  const _Pal(this.sky, this.sun, this.layers, this.accent);
  final List<Color> sky;
  final Color sun;
  final List<Color> layers; // far → near
  final Color accent;
}

const _palettes = <SceneTheme, List<_Pal>>{
  SceneTheme.mountains: [
    _Pal(
      [Color(0xFF8FD3D1), Color(0xFFF6D9B8)],
      Color(0xFFFFF1D6),
      [Color(0xFF6FAFB0), Color(0xFF3E8C8E), Color(0xFF1F6668), Color(0xFF0E4446)],
      Color(0xFF2E7D4F),
    ),
    _Pal(
      [Color(0xFFFFB98A), Color(0xFFFFE3C2)],
      Color(0xFFFFF4E0),
      [Color(0xFFC98F86), Color(0xFF8E6476), Color(0xFF5B4363), Color(0xFF2F2A45)],
      Color(0xFF4F6B4A),
    ),
  ],
  SceneTheme.snow: [
    _Pal(
      [Color(0xFF9CC9F0), Color(0xFFE7F3FB)],
      Color(0xFFFFFFFF),
      [Color(0xFFB9D3E6), Color(0xFF7FA6C4), Color(0xFF4E7799), Color(0xFF2B4D69)],
      Color(0xFFFFFFFF),
    ),
  ],
  SceneTheme.beach: [
    _Pal(
      [Color(0xFFFF9E7A), Color(0xFFFFD9A8)],
      Color(0xFFFFF3D1),
      [Color(0xFF2E9CB8), Color(0xFF1C7C9C), Color(0xFFF2D3A2), Color(0xFFE7BF85)],
      Color(0xFF1F5D3C),
    ),
    _Pal(
      [Color(0xFF7FD0EA), Color(0xFFE2F6F7)],
      Color(0xFFFFFDF0),
      [Color(0xFF34B3C9), Color(0xFF1890A8), Color(0xFFF5E1B8), Color(0xFFEACB92)],
      Color(0xFF266B45),
    ),
  ],
  SceneTheme.waterfall: [
    _Pal(
      [Color(0xFFA6DCC9), Color(0xFFE9F5E6)],
      Color(0xFFFFFDF2),
      [Color(0xFF5FA683), Color(0xFF3B805F), Color(0xFF235E44), Color(0xFF123D2C)],
      Color(0xFFE8F7FF),
    ),
  ],
  SceneTheme.forest: [
    _Pal(
      [Color(0xFFB8E0B5), Color(0xFFF2EFCF)],
      Color(0xFFFFFBE5),
      [Color(0xFF7DB283), Color(0xFF4E8F5E), Color(0xFF2D6B42), Color(0xFF17472B)],
      Color(0xFF17472B),
    ),
  ],
  SceneTheme.heritage: [
    _Pal(
      [Color(0xFFF7A26B), Color(0xFFFCE1B6)],
      Color(0xFFFFF0D2),
      [Color(0xFFD8936A), Color(0xFFB0674A), Color(0xFF7C4334), Color(0xFF4B2A25)],
      Color(0xFF4B2A25),
    ),
  ],
  SceneTheme.temple: [
    _Pal(
      [Color(0xFFF59E8B), Color(0xFFFCD9B0)],
      Color(0xFFFFF0D8),
      [Color(0xFFD2896F), Color(0xFFA35B4F), Color(0xFF6D3A3C), Color(0xFF3D2230)],
      Color(0xFF3D2230),
    ),
  ],
  SceneTheme.lake: [
    _Pal(
      [Color(0xFF9ED6E3), Color(0xFFF3E6CF)],
      Color(0xFFFFF6E0),
      [Color(0xFF7FB2BE), Color(0xFF4D8C9C), Color(0xFF3F8FA6), Color(0xFF2A6F86)],
      Color(0xFF1F5262),
    ),
  ],
  SceneTheme.desert: [
    _Pal(
      [Color(0xFFFFB27A), Color(0xFFFFE6BC)],
      Color(0xFFFFF5DA),
      [Color(0xFFF0B072), Color(0xFFE09656), Color(0xFFC97A3E), Color(0xFFA65E2C)],
      Color(0xFF7A4022),
    ),
  ],
  SceneTheme.city: [
    _Pal(
      [Color(0xFF95B8E8), Color(0xFFF2D7C7)],
      Color(0xFFFFF2E2),
      [Color(0xFF8A9FC4), Color(0xFF61789F), Color(0xFF3F5478), Color(0xFF26344F)],
      Color(0xFFFFD27A),
    ),
  ],
  SceneTheme.food: [
    _Pal(
      [Color(0xFFFFC07A), Color(0xFFFF8F6B)],
      Color(0xFFFFF0D6),
      [Color(0xFFFFE2C2), Color(0xFFF4A259), Color(0xFFD9653B), Color(0xFF8C3B22)],
      Color(0xFF2E8C6A),
    ),
    _Pal(
      [Color(0xFFF7D08A), Color(0xFFE59B6A)],
      Color(0xFFFFF7E5),
      [Color(0xFFFFF3E3), Color(0xFFE3B45C), Color(0xFFC0583C), Color(0xFF6F2E22)],
      Color(0xFF3A8C4F),
    ),
  ],
  SceneTheme.wildlife: [
    _Pal(
      [Color(0xFFF6C27F), Color(0xFFFCE9C4)],
      Color(0xFFFFF4DC),
      [Color(0xFFC2B27A), Color(0xFF8E9A5C), Color(0xFF5E7444), Color(0xFF34482C)],
      Color(0xFF2B3A22),
    ),
  ],
};

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.theme, this.seed, this.dark);

  final SceneTheme theme;
  final int seed;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final options = _palettes[theme]!;
    final pal = options[seed % options.length];
    final rect = Offset.zero & size;
    final w = size.width, h = size.height;

    // Sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: pal.sky,
        ).createShader(rect),
    );

    // Sun with glow
    if (theme != SceneTheme.food) {
      final sun = Offset(w * (0.18 + r.nextDouble() * 0.64), h * (0.2 + r.nextDouble() * 0.14));
      final sr = size.shortestSide * (0.09 + r.nextDouble() * 0.05);
      canvas.drawCircle(
        sun,
        sr * 3,
        Paint()
          ..shader = RadialGradient(colors: [pal.sun.withValues(alpha: 0.55), pal.sun.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: sun, radius: sr * 3)),
      );
      canvas.drawCircle(sun, sr, Paint()..color = pal.sun);
      _clouds(canvas, size, r);
    }

    switch (theme) {
      case SceneTheme.mountains:
        _ridges(canvas, size, r, pal, sharp: true);
        _trees(canvas, size, r, h * 0.94, pal.layers.last, 14, h * 0.12);
      case SceneTheme.snow:
        _ridges(canvas, size, r, pal, sharp: true, snow: true);
      case SceneTheme.beach:
        _beach(canvas, size, r, pal);
      case SceneTheme.waterfall:
        _waterfall(canvas, size, r, pal);
      case SceneTheme.forest:
        _ridges(canvas, size, r, pal, sharp: false, count: 2);
        _trees(canvas, size, r, h * 0.82, pal.layers[2], 16, h * 0.22);
        _trees(canvas, size, r, h * 1.0, pal.layers[3], 12, h * 0.32);
      case SceneTheme.heritage:
        _ridges(canvas, size, r, pal, sharp: false, count: 2);
        _monument(canvas, size, r, pal.layers[3], temple: false);
      case SceneTheme.temple:
        _ridges(canvas, size, r, pal, sharp: false, count: 2);
        _monument(canvas, size, r, pal.layers[3], temple: true);
      case SceneTheme.lake:
        _lake(canvas, size, r, pal);
      case SceneTheme.desert:
        _dunes(canvas, size, r, pal);
      case SceneTheme.city:
        _ridges(canvas, size, r, pal, sharp: false, count: 1);
        _skyline(canvas, size, r, pal);
      case SceneTheme.food:
        _food(canvas, size, r, pal);
      case SceneTheme.wildlife:
        _ridges(canvas, size, r, pal, sharp: false);
        _acacia(canvas, size, r, pal.accent);
    }

    if (dark) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF071012).withValues(alpha: 0.22));
    }
  }

  void _clouds(Canvas c, Size s, math.Random r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (var i = 0; i < 3; i++) {
      final x = s.width * r.nextDouble();
      final y = s.height * (0.08 + r.nextDouble() * 0.25);
      final cw = s.width * (0.12 + r.nextDouble() * 0.12);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: cw, height: cw * 0.22),
          Radius.circular(cw),
        ),
        p,
      );
    }
  }

  void _ridges(Canvas c, Size s, math.Random r, _Pal pal, {required bool sharp, bool snow = false, int count = 4}) {
    final w = s.width, h = s.height;
    for (var i = 0; i < count; i++) {
      final layer = pal.layers[(pal.layers.length - count + i).clamp(0, pal.layers.length - 1)];
      final base = h * (0.52 + i * 0.12);
      final amp = h * (0.30 - i * 0.05);
      final path = Path()..moveTo(0, h);
      final pts = 3 + r.nextInt(3);
      final peaks = <Offset>[];
      path.lineTo(0, base - amp * r.nextDouble() * 0.5);
      for (var k = 0; k <= pts; k++) {
        final x = w * k / pts;
        final y = base - amp * (0.4 + r.nextDouble() * 0.6);
        if (sharp) {
          final vx = x - w / pts / 2;
          path.lineTo(vx, base - amp * 0.15 * r.nextDouble());
          path.lineTo(x, y);
          peaks.add(Offset(x, y));
        } else {
          final prev = w * (k - 0.5) / pts;
          path.quadraticBezierTo(prev, y - amp * 0.2, x, base - amp * 0.3 * r.nextDouble());
        }
      }
      path
        ..lineTo(w, h)
        ..close();
      c.drawPath(path, Paint()..color = layer);
      if (snow && i < 2) {
        final cap = Paint()..color = Colors.white.withValues(alpha: 0.92);
        for (final pk in peaks) {
          final cw = w / pts * 0.18;
          c.drawPath(
            Path()
              ..moveTo(pk.dx, pk.dy)
              ..lineTo(pk.dx - cw, pk.dy + cw * 1.1)
              ..lineTo(pk.dx - cw * 0.3, pk.dy + cw * 0.8)
              ..lineTo(pk.dx + cw * 0.2, pk.dy + cw * 1.2)
              ..lineTo(pk.dx + cw, pk.dy + cw * 1.0)
              ..close(),
            cap,
          );
        }
      }
    }
  }

  void _trees(Canvas c, Size s, math.Random r, double baseY, Color color, int n, double maxH) {
    final p = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final x = s.width * r.nextDouble();
      final th = maxH * (0.5 + r.nextDouble() * 0.5);
      final tw = th * 0.38;
      c.drawPath(
        Path()
          ..moveTo(x, baseY - th)
          ..lineTo(x - tw / 2, baseY)
          ..lineTo(x + tw / 2, baseY)
          ..close(),
        p,
      );
    }
  }

  void _beach(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    final horizon = h * 0.55;
    c.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.layers[0], pal.layers[1]],
        ).createShader(Rect.fromLTRB(0, horizon, w, h)),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final y = horizon + (h * 0.05) * (i + 1);
      final x0 = w * r.nextDouble() * 0.6;
      c.drawLine(Offset(x0, y), Offset(x0 + w * (0.1 + r.nextDouble() * 0.25), y), wave);
    }
    final sand = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.5, h * (0.7 + r.nextDouble() * 0.06), w, h * 0.86)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(sand, Paint()..color = pal.layers[2]);
    c.drawPath(
      Path()
        ..moveTo(0, h * 0.9)
        ..quadraticBezierTo(w * 0.6, h * 0.84, w, h * 0.95)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = pal.layers[3],
    );
    _palm(c, Offset(w * (0.08 + r.nextDouble() * 0.15), h * 0.9), h * 0.55, pal.accent, r, flip: false);
    if (r.nextBool()) {
      _palm(c, Offset(w * (0.8 + r.nextDouble() * 0.12), h * 0.94), h * 0.45, pal.accent, r, flip: true);
    }
  }

  void _palm(Canvas c, Offset base, double height, Color color, math.Random r, {required bool flip}) {
    final dir = flip ? -1.0 : 1.0;
    final top = Offset(base.dx + dir * height * 0.18, base.dy - height);
    final trunk = Paint()
      ..color = color
      ..strokeWidth = height * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + dir * height * 0.02, base.dy - height * 0.6, top.dx, top.dy),
      trunk,
    );
    final leaf = Paint()..color = color;
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * 0.55;
      final len = height * (0.28 + r.nextDouble() * 0.08);
      final end = top + Offset(math.cos(a) * len, math.sin(a) * len * 0.6 + len * 0.25);
      final ctrl = top + Offset(math.cos(a) * len * 0.5, math.sin(a) * len * 0.6 - len * 0.12);
      c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy - len * 0.06, end.dx, end.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy + len * 0.06, top.dx, top.dy),
        leaf,
      );
    }
  }

  void _waterfall(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    _ridges(c, s, r, pal, sharp: false, count: 1);
    final gapL = w * (0.38 + r.nextDouble() * 0.08);
    final gapR = gapL + w * 0.14;
    final top = h * 0.3;
    final cliff = Paint()..color = pal.layers[2];
    c.drawPath(
      Path()
        ..moveTo(0, top + h * 0.05)
        ..lineTo(gapL, top)
        ..lineTo(gapL, h)
        ..lineTo(0, h)
        ..close(),
      cliff,
    );
    c.drawPath(
      Path()
        ..moveTo(gapR, top)
        ..lineTo(w, top - h * 0.05)
        ..lineTo(w, h)
        ..lineTo(gapR, h)
        ..close(),
      cliff,
    );
    final fall = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [pal.accent, pal.accent.withValues(alpha: 0.75)],
      ).createShader(Rect.fromLTRB(gapL, top, gapR, h));
    c.drawRect(Rect.fromLTRB(gapL, top, gapR, h * 0.86), fall);
    final streak = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4;
    for (var i = 0; i < 6; i++) {
      final x = gapL + (gapR - gapL) * r.nextDouble();
      c.drawLine(Offset(x, top + h * 0.05 * r.nextDouble()), Offset(x, h * (0.6 + r.nextDouble() * 0.25)), streak);
    }
    c.drawOval(
      Rect.fromCenter(center: Offset((gapL + gapR) / 2, h * 0.88), width: w * 0.5, height: h * 0.1),
      Paint()..color = pal.accent.withValues(alpha: 0.9),
    );
    _trees(c, s, r, h * 1.02, pal.layers[3], 10, h * 0.3);
  }

  void _monument(Canvas c, Size s, math.Random r, Color color, {required bool temple}) {
    final w = s.width, h = s.height;
    final p = Paint()..color = color;
    final base = h * 0.86;
    c.drawRect(Rect.fromLTRB(0, base, w, h), p);
    final cx = w * (0.4 + r.nextDouble() * 0.2);
    if (temple) {
      // Stepped gopuram
      final tiers = 5;
      final bw = w * 0.26;
      final th = h * 0.09;
      for (var i = 0; i < tiers; i++) {
        final tw = bw * (1 - i * 0.16);
        c.drawRect(Rect.fromCenter(center: Offset(cx, base - th * (i + 0.5)), width: tw, height: th + 1), p);
      }
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, base - th * tiers - th * 0.3), width: bw * 0.3, height: th * 0.9),
        p,
      );
      c.drawRect(
        Rect.fromCenter(center: Offset(cx, base - th * 0.5), width: bw * 0.16, height: th),
        Paint()..color = color.withValues(alpha: 0.6),
      );
      for (final dx in [-0.3, 0.3]) {
        c.drawRect(Rect.fromLTWH(cx + w * dx - w * 0.04, base - h * 0.14, w * 0.08, h * 0.14), p);
      }
    } else {
      // Domes and arches
      final bw = w * 0.42;
      final bh = h * 0.2;
      final body = Rect.fromLTWH(cx - bw / 2, base - bh, bw, bh);
      c.drawRect(body, p);
      c.drawArc(
        Rect.fromCenter(center: Offset(cx, base - bh), width: bw * 0.42, height: bw * 0.42),
        math.pi,
        math.pi,
        true,
        p,
      );
      for (final dx in [-0.36, 0.36]) {
        final tx = cx + bw * dx;
        c.drawRect(Rect.fromLTWH(tx - w * 0.02, base - bh * 1.7, w * 0.04, bh * 1.7), p);
        c.drawCircle(Offset(tx, base - bh * 1.7), w * 0.028, p);
      }
      final arch = Paint()..color = Colors.white.withValues(alpha: 0.18);
      for (var i = 0; i < 3; i++) {
        final ax = cx - bw * 0.3 + i * bw * 0.3;
        c.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromCenter(center: Offset(ax, base - bh * 0.35), width: bw * 0.16, height: bh * 0.6),
            topLeft: Radius.circular(bw),
            topRight: Radius.circular(bw),
          ),
          arch,
        );
      }
    }
  }

  void _lake(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    _ridges(c, s, r, _Pal(pal.sky, pal.sun, [pal.layers[0], pal.layers[1]], pal.accent), sharp: true, count: 2);
    final shore = h * 0.68;
    final water = Rect.fromLTRB(0, shore, w, h);
    c.drawRect(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.layers[2], pal.layers[3]],
        ).createShader(water),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 7; i++) {
      final y = shore + (h - shore) * (i + 1) / 8;
      final x = w * r.nextDouble() * 0.7;
      c.drawLine(Offset(x, y), Offset(x + w * 0.05 + w * 0.2 * r.nextDouble(), y), shine);
    }
    _trees(c, s, r, shore + 2, pal.accent, 9, h * 0.14);
    // Boat
    final bx = w * (0.55 + r.nextDouble() * 0.25);
    final by = shore + (h - shore) * 0.45;
    c.drawPath(
      Path()
        ..moveTo(bx - w * 0.06, by)
        ..lineTo(bx + w * 0.06, by)
        ..lineTo(bx + w * 0.04, by + h * 0.025)
        ..lineTo(bx - w * 0.04, by + h * 0.025)
        ..close(),
      Paint()..color = pal.accent,
    );
  }

  void _dunes(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    for (var i = 0; i < 4; i++) {
      final y = h * (0.55 + i * 0.12);
      c.drawPath(
        Path()
          ..moveTo(0, y + h * 0.05)
          ..quadraticBezierTo(w * (0.2 + r.nextDouble() * 0.6), y - h * (0.08 + r.nextDouble() * 0.08), w, y + h * 0.02)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = pal.layers[i],
      );
      if (i == 1) {
        // Fort silhouette on the ridge
        final fx = w * (0.55 + r.nextDouble() * 0.2);
        final fp = Paint()..color = pal.accent;
        final fw = w * 0.28, fh = h * 0.12;
        c.drawRect(Rect.fromLTWH(fx - fw / 2, y - fh, fw, fh + h * 0.04), fp);
        for (var k = 0; k < 7; k++) {
          c.drawRect(Rect.fromLTWH(fx - fw / 2 + k * fw / 6.5, y - fh - h * 0.02, fw / 14, h * 0.02), fp);
        }
        c.drawRect(Rect.fromLTWH(fx - fw * 0.1, y - fh * 1.6, fw * 0.2, fh * 0.6), fp);
      }
    }
  }

  void _skyline(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    final base = h * 0.9;
    var x = 0.0;
    final p = Paint()..color = pal.layers[3];
    final win = Paint()..color = pal.accent.withValues(alpha: 0.7);
    while (x < w) {
      final bw = w * (0.06 + r.nextDouble() * 0.08);
      final bh = h * (0.15 + r.nextDouble() * 0.35);
      c.drawRect(Rect.fromLTWH(x, base - bh, bw, bh), p);
      for (var k = 0; k < 4; k++) {
        if (r.nextDouble() < 0.5) {
          c.drawRect(Rect.fromLTWH(x + bw * 0.25, base - bh + bh * (0.15 + k * 0.2), bw * 0.18, bh * 0.06), win);
        }
      }
      x += bw + 2;
    }
    c.drawRect(Rect.fromLTRB(0, base, w, h), p);
  }

  void _food(Canvas c, Size s, math.Random r, _Pal pal) {
    final w = s.width, h = s.height;
    // Scattered spice dots
    for (var i = 0; i < 26; i++) {
      c.drawCircle(
        Offset(w * r.nextDouble(), h * r.nextDouble()),
        1.5 + r.nextDouble() * 3,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
    // Banana leaf
    final leafC = Offset(w * 0.5, h * 0.58);
    c.save();
    c.translate(leafC.dx, leafC.dy);
    c.rotate(-0.25 + r.nextDouble() * 0.2);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.95, height: h * 0.62), Paint()..color = pal.accent);
    c.drawLine(
      Offset(-w * 0.45, 0),
      Offset(w * 0.45, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
    c.restore();
    // Bowls
    final bowls = [
      (Offset(w * 0.34, h * 0.56), h * 0.17, pal.layers[1]),
      (Offset(w * 0.6, h * 0.5), h * 0.13, pal.layers[2]),
      (Offset(w * 0.66, h * 0.7), h * 0.11, pal.layers[0]),
      (Offset(w * 0.45, h * 0.76), h * 0.09, pal.layers[3]),
    ];
    for (final (o, rad, col) in bowls) {
      c.drawCircle(o + const Offset(0, 3), rad, Paint()..color = Colors.black.withValues(alpha: 0.12));
      c.drawCircle(o, rad, Paint()..color = Colors.white);
      c.drawCircle(o, rad * 0.78, Paint()..color = col);
    }
    // Steam
    final steam = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final sx = w * 0.3 + i * w * 0.04;
      c.drawPath(
        Path()
          ..moveTo(sx, h * 0.34)
          ..cubicTo(sx - 8, h * 0.28, sx + 8, h * 0.24, sx, h * 0.17),
        steam,
      );
    }
  }

  void _acacia(Canvas c, Size s, math.Random r, Color color) {
    final w = s.width, h = s.height;
    final p = Paint()..color = color;
    for (var i = 0; i < 2; i++) {
      final x = w * (0.2 + i * 0.5 + r.nextDouble() * 0.15);
      final base = h * (0.86 + i * 0.05);
      final th = h * (0.28 - i * 0.05);
      c.drawRect(Rect.fromLTWH(x - 2.5, base - th, 5, th), p);
      c.drawOval(Rect.fromCenter(center: Offset(x, base - th), width: w * 0.28, height: h * 0.08), p);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.theme != theme || old.seed != seed || old.dark != dark;
}
