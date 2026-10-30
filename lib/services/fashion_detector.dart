import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../models.dart';

class FashionDetection {
  const FashionDetection({
    required this.classId,
    required this.displayName,
    required this.category,
    required this.confidence,
    required this.cropJpeg,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int classId;
  final String displayName;
  final Category category;
  final double confidence;
  final Uint8List cropJpeg;
  final int x;
  final int y;
  final int width;
  final int height;
}

class FashionDetector {
  FashionDetector._();

  static final FashionDetector instance = FashionDetector._();
  static const _assetPath = 'assets/models/fashionpedia_yolov8n.onnx';
  static const _fallbackSize = 640;
  static const _classCount = 46;

  OrtSession? _session;

  static const _names = <String>[
    '衬衫',
    '上衣',
    '毛衣',
    '开衫',
    '夹克',
    '马甲',
    '裤子',
    '短裤',
    '裙子',
    '大衣',
    '连衣裙',
    '连体衣',
    '披风',
    '眼镜',
    '帽子',
    '头饰',
    '领带',
    '手套',
    '手表',
    '腰带',
    '腿套',
    '连裤袜',
    '袜子',
    '鞋子',
    '包包',
    '围巾',
    '雨伞',
    '兜帽',
    '领口',
    '翻领',
    '肩章',
    '袖子',
    '口袋',
    '领口装饰',
    '扣件',
    '拉链',
    '贴花',
    '珠饰',
    '蝴蝶结',
    '花饰',
    '流苏',
    '饰带',
    '铆钉',
    '荷叶边',
    '亮片',
    '穗饰',
  ];

  Future<OrtSession> _ensureSession() async {
    if (_session != null) return _session!;
    _session = await OnnxRuntime().createSessionFromAsset(
      _assetPath,
      options: OrtSessionOptions(intraOpNumThreads: 2),
    );
    return _session!;
  }

  Future<List<FashionDetection>> detect(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.28,
  }) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw StateError('无法解码图片');
    final source = img.bakeOrientation(decoded);
    final session = await _ensureSession();

    var inputW = _fallbackSize;
    var inputH = _fallbackSize;
    try {
      final info = await session.getInputInfo();
      if (info.isNotEmpty && info.first['shape'] is List) {
        final shape = List<dynamic>.from(info.first['shape'] as List);
        if (shape.length == 4) {
          final h = shape[2] is num ? (shape[2] as num).toInt() : 0;
          final w = shape[3] is num ? (shape[3] as num).toInt() : 0;
          if (h > 0 && w > 0) {
            inputH = h;
            inputW = w;
          }
        }
      }
    } catch (_) {
      // This model is exported as 640x640; use that if tensor info is unavailable.
    }

    final scale = math.min(inputW / source.width, inputH / source.height);
    final resizedW = math.max(1, (source.width * scale).round()).toInt();
    final resizedH = math.max(1, (source.height * scale).round()).toInt();
    final padX = (inputW - resizedW) ~/ 2;
    final padY = (inputH - resizedH) ~/ 2;
    final resized = img.copyResize(
      source,
      width: resizedW,
      height: resizedH,
      interpolation: img.Interpolation.linear,
    );

    final plane = inputW * inputH;
    final tensorData = Float32List(plane * 3);
    const padValue = 114.0 / 255.0;
    tensorData.fillRange(0, tensorData.length, padValue);
    for (var y = 0; y < resizedH; y++) {
      final dy = y + padY;
      for (var x = 0; x < resizedW; x++) {
        final dx = x + padX;
        final p = resized.getPixel(x, y);
        final index = dy * inputW + dx;
        tensorData[index] = p.r.toDouble() / 255.0;
        tensorData[plane + index] = p.g.toDouble() / 255.0;
        tensorData[plane * 2 + index] = p.b.toDouble() / 255.0;
      }
    }

    final input = await OrtValue.fromList(tensorData, [1, 3, inputH, inputW]);
    Map<String, OrtValue> outputs = {};
    try {
      outputs = await session.run({session.inputNames.first: input});
      if (outputs.isEmpty) return const [];
      final outputName = session.outputNames.isNotEmpty
          ? session.outputNames.first
          : outputs.keys.first;
      final output = outputs[outputName] ?? outputs.values.first;
      final flat = await output.asFlattenedList();
      final boxes = _decodeOutput(
        flat,
        output.shape,
        confidenceThreshold,
        source.width,
        source.height,
        resizedW / source.width,
        resizedH / source.height,
        padX.toDouble(),
        padY.toDouble(),
      );
      final kept = _mergeShoes(_nms(boxes, 0.45))
        ..sort((a, b) => b.score.compareTo(a.score));

      final results = <FashionDetection>[];
      for (final box in kept.take(12)) {
        final left = math.max(0, (box.x1 - box.width * .08).floor()).toInt();
        final top = math.max(0, (box.y1 - box.height * .08).floor()).toInt();
        final right = math
            .min(source.width, (box.x2 + box.width * .08).ceil())
            .toInt();
        final bottom = math
            .min(source.height, (box.y2 + box.height * .08).ceil())
            .toInt();
        if (right <= left || bottom <= top) continue;
        final crop = img.copyCrop(
          source,
          x: left,
          y: top,
          width: right - left,
          height: bottom - top,
        );
        results.add(
          FashionDetection(
            classId: box.classId,
            displayName: _displayName(box.classId),
            category: _categoryFor(box.classId),
            confidence: box.score,
            cropJpeg: img.encodeJpg(crop, quality: 88),
            x: left,
            y: top,
            width: right - left,
            height: bottom - top,
          ),
        );
      }
      return results;
    } finally {
      await input.dispose();
      for (final output in outputs.values) {
        await output.dispose();
      }
    }
  }

  List<_Box> _decodeOutput(
    List<dynamic> data,
    List<int> shape,
    double threshold,
    int sourceW,
    int sourceH,
    double scaleX,
    double scaleY,
    double padX,
    double padY,
  ) {
    if (shape.length != 3 || data.isEmpty) return const [];
    final d1 = shape[1];
    final d2 = shape[2];
    final channelFirst = d1 < d2;
    final channels = channelFirst ? d1 : d2;
    final count = channelFirst ? d2 : d1;
    if (channels < 6 || count <= 0) return const [];

    double at(int channel, int index) {
      final raw = channelFirst
          ? data[channel * count + index]
          : data[index * channels + channel];
      return (raw as num).toDouble();
    }

    final boxes = <_Box>[];
    if (channels == 6) {
      for (var i = 0; i < count; i++) {
        final score = at(4, i);
        final classId = at(5, i).round();
        if (score < threshold || !_isWardrobeClass(classId)) continue;
        final box = _mapBox(
          at(0, i),
          at(1, i),
          at(2, i),
          at(3, i),
          score,
          classId,
          sourceW,
          sourceH,
          scaleX,
          scaleY,
          padX,
          padY,
        );
        if (box != null) boxes.add(box);
      }
      return boxes;
    }

    final classChannels = math.min(_classCount, channels - 4).toInt();
    for (var i = 0; i < count; i++) {
      var bestClass = -1;
      var bestScore = 0.0;
      for (var c = 0; c < classChannels; c++) {
        final score = at(4 + c, i);
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }
      if (bestScore < threshold || !_isWardrobeClass(bestClass)) continue;
      final cx = at(0, i);
      final cy = at(1, i);
      final w = at(2, i);
      final h = at(3, i);
      final box = _mapBox(
        cx - w / 2,
        cy - h / 2,
        cx + w / 2,
        cy + h / 2,
        bestScore,
        bestClass,
        sourceW,
        sourceH,
        scaleX,
        scaleY,
        padX,
        padY,
      );
      if (box != null) boxes.add(box);
    }
    boxes.sort((a, b) => b.score.compareTo(a.score));
    return boxes.length > 300 ? boxes.sublist(0, 300) : boxes;
  }

  _Box? _mapBox(
    double x1,
    double y1,
    double x2,
    double y2,
    double score,
    int classId,
    int sourceW,
    int sourceH,
    double scaleX,
    double scaleY,
    double padX,
    double padY,
  ) {
    final left = ((x1 - padX) / scaleX)
        .clamp(0.0, sourceW.toDouble())
        .toDouble();
    final top = ((y1 - padY) / scaleY)
        .clamp(0.0, sourceH.toDouble())
        .toDouble();
    final right = ((x2 - padX) / scaleX)
        .clamp(0.0, sourceW.toDouble())
        .toDouble();
    final bottom = ((y2 - padY) / scaleY)
        .clamp(0.0, sourceH.toDouble())
        .toDouble();
    if (right - left < 8 || bottom - top < 8) return null;
    return _Box(left, top, right, bottom, score, classId);
  }

  List<_Box> _nms(List<_Box> boxes, double iouThreshold) {
    final sorted = [...boxes]..sort((a, b) => b.score.compareTo(a.score));
    final kept = <_Box>[];
    for (final candidate in sorted) {
      final category = _categoryFor(candidate.classId);
      final suppressed = kept.any(
        (other) =>
            _categoryFor(other.classId) == category &&
            _iou(candidate, other) > iouThreshold,
      );
      if (!suppressed) kept.add(candidate);
    }
    return kept;
  }

  List<_Box> _mergeShoes(List<_Box> boxes) {
    final shoes = boxes.where((b) => b.classId == 23).toList();
    if (shoes.length < 2) return boxes;
    final others = boxes.where((b) => b.classId != 23).toList();
    final x1 = shoes.map((b) => b.x1).reduce(math.min);
    final y1 = shoes.map((b) => b.y1).reduce(math.min);
    final x2 = shoes.map((b) => b.x2).reduce(math.max);
    final y2 = shoes.map((b) => b.y2).reduce(math.max);
    final score = shoes.map((b) => b.score).reduce(math.max);
    return [...others, _Box(x1, y1, x2, y2, score, 23)];
  }

  double _iou(_Box a, _Box b) {
    final left = math.max(a.x1, b.x1);
    final top = math.max(a.y1, b.y1);
    final right = math.min(a.x2, b.x2);
    final bottom = math.min(a.y2, b.y2);
    final iw = math.max(0.0, right - left);
    final ih = math.max(0.0, bottom - top);
    final intersection = iw * ih;
    final union = a.width * a.height + b.width * b.height - intersection;
    return union <= 0 ? 0 : intersection / union;
  }

  static bool _isWardrobeClass(int classId) => classId >= 0 && classId <= 26;

  static String _displayName(int classId) =>
      classId >= 0 && classId < _names.length ? _names[classId] : '单品';

  static Category _categoryFor(int classId) {
    switch (classId) {
      case 0:
      case 1:
      case 2:
        return Category.top;
      case 3:
      case 4:
      case 5:
      case 9:
      case 12:
        return Category.outerwear;
      case 6:
        return Category.pants;
      case 7:
        return Category.shorts;
      case 8:
        return Category.skirt;
      case 10:
      case 11:
        return Category.dress;
      case 23:
        return Category.shoes;
      case 24:
        return Category.bag;
      default:
        return Category.accessory;
    }
  }
}

class _Box {
  const _Box(this.x1, this.y1, this.x2, this.y2, this.score, this.classId);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double score;
  final int classId;

  double get width => x2 - x1;
  double get height => y2 - y1;
}
