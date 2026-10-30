import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models.dart';
import '../demo_assets.dart';
import '../l10n/app_localizations.dart';
import 'local_file_image.dart';

// Keep only the current image for each item, including same-length edits.
final Map<String, (String, Uint8List)> _decoded = {};
Uint8List? imageBytesOf(ClothingItem item) {
  final source = item.imageBase64;
  if (source == null || source.isEmpty) return null;
  final cached = _decoded[item.id];
  if (cached != null && cached.$1 == source) return cached.$2;
  try {
    final bytes = base64Decode(source);
    if (_decoded.length >= 100) _decoded.remove(_decoded.keys.first);
    _decoded[item.id] = (source, bytes);
    return bytes;
  } on FormatException {
    return null;
  }
}

bool hasPersonalImage(ClothingItem item) =>
    (item.imageBase64?.isNotEmpty ?? false) ||
    (item.imagePath?.isNotEmpty ?? false);

/// Offline wardrobe illustrations are used until a personal photo is added.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.item, {super.key, this.radius = 16, this.iconSize});
  final ClothingItem item;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytesOf(item);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final art = ColoredBox(
      color: dark
          ? const Color(0xFF303B31)
          : Color.lerp(const Color(0xFFF1F0E9), item.color, 0.045)!,
      child: GarmentArt(item: item),
    );
    final imagePath = item.imagePath;
    final image = bytes != null
        ? Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => art,
          )
        : imagePath != null && imagePath.isNotEmpty
        ? localFileImage(imagePath, fit: BoxFit.cover, fallback: art)
        : art;
    return Semantics(
      label: context.itemName(item),
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      ),
    );
  }
}

class GarmentArt extends StatelessWidget {
  const GarmentArt({super.key, required this.item});
  final ClothingItem item;
  @override
  Widget build(BuildContext context) {
    final asset = demoAssetFor(item);
    if (asset != null) {
      return LayoutBuilder(
        builder: (_, constraints) => Padding(
          padding: EdgeInsets.all(constraints.biggest.shortestSide * 0.08),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _illustration(),
          ),
        ),
      );
    }
    return _illustration();
  }

  Widget _illustration() => CustomPaint(
    painter: _GarmentPainter(item),
    child: const SizedBox.expand(),
  );
}

class _GarmentPainter extends CustomPainter {
  _GarmentPainter(this.item);
  final ClothingItem item;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 220).clamp(0.0, size.height / 240);
    canvas.translate(
      (size.width - 220 * scale) / 2,
      (size.height - 240 * scale) / 2,
    );
    canvas.scale(scale);
    final color = Color.lerp(item.color, const Color(0xFFB7B1A1), 0.13)!;
    final seam = Color.lerp(color, const Color(0xFF191F1B), 0.24)!;
    final edge = Paint()
      ..color = seam.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x, double y, double x2, double y2) =>
        canvas.drawLine(Offset(x, y), Offset(x2, y2), edge);
    void garment(Path path) {
      canvas.drawShadow(
        path,
        const Color(0xFF253626).withValues(alpha: 0.22),
        5,
        false,
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.14)!,
              color,
              Color.lerp(color, Colors.black, 0.08)!,
            ],
          ).createShader(const Rect.fromLTWH(20, 25, 180, 190)),
      );
      canvas.drawPath(path, edge);
    }

    Path poly(List<Offset> points) => Path()..addPolygon(points, true);
    switch (item.category) {
      case Category.top:
      case Category.outerwear:
        final coat = item.category == Category.outerwear;
        final long =
            coat || item.name.contains('针织') || item.name.contains('衬衫');
        final path = poly([
          const Offset(80, 47),
          const Offset(96, 42),
          const Offset(124, 42),
          const Offset(140, 47),
          Offset(181, long ? 139 : 85),
          Offset(long ? 160 : 158, long ? 147 : 109),
          const Offset(146, 91),
          Offset(148, coat ? 207 : 184),
          Offset(72, coat ? 207 : 184),
          const Offset(74, 91),
          Offset(long ? 60 : 62, long ? 147 : 109),
          Offset(39, long ? 139 : 85),
        ]);
        garment(path);
        if (item.name.contains('条纹')) {
          canvas.save();
          canvas.clipPath(path);
          final stripePaint = Paint()
            ..color = const Color(0xFFECEDE7)
            ..strokeWidth = 6;
          for (double y = 76; y < 182; y += 15) {
            canvas.drawLine(Offset(35, y), Offset(185, y), stripePaint);
          }
          canvas.restore();
        }
        if (coat || item.name.contains('衬衫')) {
          garment(
            poly([
              const Offset(96, 43),
              const Offset(110, 58),
              const Offset(95, 76),
              const Offset(86, 47),
            ]),
          );
          garment(
            poly([
              const Offset(124, 43),
              const Offset(110, 58),
              const Offset(125, 76),
              const Offset(134, 47),
            ]),
          );
          line(110, 60, 110, coat ? 207 : 184);
          for (double y = 86; y < (coat ? 190 : 174); y += 21) {
            canvas.drawCircle(Offset(114, y), 1.7, Paint()..color = seam);
          }
          if (coat) {
            line(80, 144, 99, 144);
            line(122, 144, 141, 144);
            line(75, 169, 146, 169);
          } else {
            line(124, 89, 139, 89);
            line(124, 89, 124, 106);
            line(139, 89, 139, 106);
            line(124, 106, 139, 106);
          }
        } else {
          final neck = Path()
            ..moveTo(96, 43)
            ..cubicTo(97, 65, 123, 65, 124, 43);
          canvas.drawPath(neck, edge..strokeWidth = 3);
          edge.strokeWidth = 1.1;
        }
        line(77, coat ? 199 : 177, 143, coat ? 199 : 177);
        if (item.name.contains('针织')) {
          canvas.save();
          canvas.clipPath(path);
          final rib = Paint()
            ..color = seam.withValues(alpha: 0.13)
            ..strokeWidth = 0.8;
          for (double x = 40; x < 182; x += 5) {
            canvas.drawLine(Offset(x, 50), Offset(x, 183), rib);
          }
          canvas.restore();
        }
      case Category.bottom:
      case Category.pants:
      case Category.shorts:
      case Category.skirt:
        if (item.category == Category.skirt || item.name.contains('裙')) {
          final path = poly([
            const Offset(78, 52),
            const Offset(142, 52),
            const Offset(168, 192),
            const Offset(52, 192),
          ]);
          garment(path);
          line(77, 61, 143, 61);
          for (double x = 84; x < 140; x += 10) {
            line(x, 62, 110 + (x - 110) * 1.65, 190);
          }
        } else {
          garment(
            poly([
              const Offset(72, 38),
              const Offset(147, 38),
              const Offset(157, 205),
              const Offset(118, 205),
              const Offset(109, 105),
              const Offset(101, 205),
              const Offset(63, 205),
            ]),
          );
          line(72, 49, 147, 49);
          line(109, 50, 109, 98);
          line(109, 98, 116, 91);
          canvas.drawCircle(const Offset(111, 43), 2, Paint()..color = seam);
          final pockets = Path()
            ..moveTo(76, 51)
            ..quadraticBezierTo(78, 75, 93, 75)
            ..moveTo(142, 51)
            ..quadraticBezierTo(142, 75, 126, 75);
          canvas.drawPath(pockets, edge);
          line(68, 197, 99, 197);
          line(120, 197, 153, 197);
        }
      case Category.dress:
        final path = Path()
          ..moveTo(86, 38)
          ..lineTo(96, 38)
          ..quadraticBezierTo(109, 57, 123, 38)
          ..lineTo(134, 38)
          ..lineTo(142, 87)
          ..lineTo(130, 111)
          ..lineTo(166, 202)
          ..quadraticBezierTo(111, 215, 54, 202)
          ..lineTo(90, 111)
          ..lineTo(78, 87)
          ..close();
        garment(path);
        line(91, 111, 129, 111);
        canvas.save();
        canvas.clipPath(path);
        for (var row = 0; row < 9; row++) {
          for (var col = 0; col < 7; col++) {
            final point = Offset(
              65 + col * 16 + (row.isOdd ? 8 : 0),
              61 + row * 17,
            );
            canvas.drawCircle(
              point,
              2.4,
              Paint()..color = const Color(0xFFFFF6E5),
            );
            canvas.drawCircle(
              point.translate(2, 3),
              1.6,
              Paint()..color = const Color(0xFF71896B),
            );
          }
        }
        canvas.restore();
      case Category.shoes:
        for (var i = 0; i < 2; i++) {
          canvas.save();
          canvas.translate(i * 12, i * 41.0);
          canvas.rotate(-0.12);
          final shoe = Path()
            ..moveTo(48, 91)
            ..lineTo(77, 83)
            ..quadraticBezierTo(90, 107, 123, 108)
            ..lineTo(164, 125)
            ..quadraticBezierTo(185, 138, 164, 149)
            ..lineTo(51, 149)
            ..quadraticBezierTo(42, 132, 48, 91)
            ..close();
          garment(shoe);
          canvas.drawPath(
            Path()
              ..moveTo(48, 141)
              ..lineTo(173, 141),
            edge..strokeWidth = 4,
          );
          edge.strokeWidth = 1.1;
          if (!item.name.contains('乐福')) {
            for (double x = 97; x < 132; x += 9) {
              line(x, 111 + (x - 97) * 0.35, x - 8, 122 + (x - 97) * 0.35);
            }
          } else {
            line(86, 116, 129, 126);
            line(86, 122, 123, 132);
          }
          canvas.restore();
        }
      case Category.bag:
        final handle = Path()
          ..moveTo(83, 96)
          ..lineTo(83, 65)
          ..cubicTo(83, 26, 137, 26, 137, 65)
          ..lineTo(137, 96);
        canvas.drawPath(
          handle,
          Paint()
            ..color = seam
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
        final bag = Path()
          ..moveTo(59, 82)
          ..lineTo(160, 82)
          ..lineTo(170, 193)
          ..quadraticBezierTo(110, 209, 50, 193)
          ..close();
        garment(bag);
        line(65, 92, 155, 92);
        line(63, 97, 59, 187);
        line(155, 97, 161, 187);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(95, 130, 29, 25),
            const Radius.circular(3),
          ),
          edge,
        );
      case Category.accessory:
        garment(
          poly([
            const Offset(71, 47),
            const Offset(108, 41),
            const Offset(146, 151),
            const Offset(113, 166),
          ]),
        );
        garment(
          poly([
            const Offset(140, 47),
            const Offset(105, 44),
            const Offset(75, 196),
            const Offset(111, 202),
          ]),
        );
        for (double x = 75; x < 111; x += 5) {
          line(x, 196, x - 2, 212);
        }
        for (double x = 115; x < 145; x += 5) {
          line(x, 159, x + 5, 171);
        }
        for (double y = 85; y < 182; y += 9) {
          line(102 - (y - 85) / 5, y, 128 - (y - 85) / 5, y + 4);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _GarmentPainter old) =>
      old.item.color != item.color ||
      old.item.category != item.category ||
      old.item.name != item.name;
}

class OutfitCollage extends StatelessWidget {
  const OutfitCollage(this.items, {super.key, this.gap = 4});
  final List<ClothingItem> items;
  final double gap;
  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    if (shown.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.style_outlined)),
      );
    }
    if (shown.length == 1) return ItemThumb(shown.first);
    final rows = [
      shown.take(2).toList(),
      if (shown.length > 2) shown.skip(2).toList(),
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(child: ItemThumb(rows[r][i], radius: 12)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
