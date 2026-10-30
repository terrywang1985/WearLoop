import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../services/fashion_detector.dart';
import '../store.dart';

class SmartImportScreen extends StatefulWidget {
  const SmartImportScreen({super.key});

  @override
  State<SmartImportScreen> createState() => _SmartImportScreenState();
}

class _SmartImportScreenState extends State<SmartImportScreen> {
  Uint8List? _sourceBytes;
  List<_Candidate> _candidates = [];
  bool _loading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sourceBytes = bytes;
        _candidates = [];
        _error = null;
        _loading = true;
      });

      final detections = await FashionDetector.instance.detect(bytes);
      if (!mounted) return;
      setState(() {
        _candidates = detections.map(_Candidate.new).toList();
        _loading = false;
        if (detections.isEmpty) {
          _error = context.tr('没有识别到明确的服装单品。可以换一张光线更好、人物更完整的照片再试。');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.tr('本地识别失败，请重试或手动添加。');
      });
    }
  }

  Future<void> _save() async {
    final selected = _candidates.where((c) => c.selected).toList();
    if (selected.isEmpty || _loading) return;

    setState(() => _loading = true);
    final store = context.read<WardrobeStore>();
    final now = DateTime.now();
    final newItems = <ClothingItem>[];

    for (final candidate in selected) {
      if (!mounted) return;
      final d = candidate.detection;
      final localizedName = context.tr(d.displayName);
      final localizedNotes = context.tr('本地 AI 识别 · {confidence}%', {
        'confidence': (d.confidence * 100).round(),
      });
      final id = store.newId();
      final saved = await store.saveImageBytes(d.cropJpeg, id);
      newItems.add(
        ClothingItem(
          id: id,
          name: localizedName,
          category: candidate.category,
          color: kPresetColors[2],
          imageBase64: saved.imageBase64,
          imagePath: saved.imagePath,
          notes: localizedNotes,
          createdAt: now,
        ),
      );
    }

    if (!mounted) return;
    store.addItems(newItems);
    Navigator.pop(context, selected.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _candidates.where((c) => c.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('本地 AI 智能导入')),
        actions: [
          if (selectedCount > 0)
            TextButton(
              onPressed: _save,
              child: Text(
                context.tr('加入衣橱 ({count})', {'count': selectedCount}),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: .55,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        '完全本地识别：照片不会上传。全身照会自动拆成上衣、裤子、裙子、鞋子、包等单品；单件照片也可以直接识别。',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(context.tr('拍全身照')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.tr('从相册选')),
                  ),
                ),
              ],
            ),
            if (_sourceBytes != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  _sourceBytes!,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Center(child: Text(context.tr('正在手机本地识别并拆分单品…'))),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_candidates.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                context.tr('识别到 {count} 件单品', {'count': _candidates.length}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('识别结果可以取消勾选或手动改分类，再一次性加入衣橱。'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _candidates.length; i++)
                _candidateTile(i, theme),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: selectedCount == 0 ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  context.tr('加入衣橱 ({count})', {'count': selectedCount}),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _candidateTile(int index, ThemeData theme) {
    final candidate = _candidates[index];
    final d = candidate.detection;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(
              value: candidate.selected,
              onChanged: (value) =>
                  setState(() => candidate.selected = value ?? false),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                d.cropJpeg,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('{name} · {confidence}%', {
                      'name': context.tr(d.displayName),
                      'confidence': (d.confidence * 100).round(),
                    }),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Category>(
                    initialValue: candidate.category,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: context.tr('归入目录'),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      for (final category in Category.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(
                            '${category.emoji} ${context.categoryLabel(category)}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => candidate.category = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Candidate {
  _Candidate(this.detection) : category = detection.category;

  final FashionDetection detection;
  bool selected = true;
  Category category;
}
