import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../demo_assets.dart';
import '../services/fashion_detector.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';

class ItemEditScreen extends StatefulWidget {
  const ItemEditScreen({super.key, this.item, this.initialCategory});
  final ClothingItem? item;
  final Category? initialCategory;

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  bool _localizedPrice = false;
  String? _initialDisplayName;
  late Category _category;
  late Color _color;
  Set<Season> _seasons = {};
  DateTime? _purchaseDate;
  String? _imageBase64;
  String? _imagePath;
  Uint8List? _pendingImageBytes;
  String? _aiHint;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _category = it?.category ?? widget.initialCategory ?? Category.top;
    _color = it?.color ?? kPresetColors[0];
    _seasons = {...?it?.seasons};
    _purchaseDate = it?.purchaseDate;
    _imageBase64 = it?.imageBase64;
    _imagePath = it?.imagePath;
    _name.text = it?.name ?? '';
    _brand.text = it?.brand ?? '';
    _price.text = it?.price?.toString() ?? '';
    _notes.text = it?.notes ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localizedPrice) {
      _localizedPrice = true;
      if (widget.item case final item?) {
        _initialDisplayName = context.itemName(item);
        _name.text = _initialDisplayName!;
      }
      if (widget.item?.price case final price?) {
        _price.text = context.editNumber(price);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingImageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
        _aiHint = context.tr('本地 AI 识别中…');
      });
      try {
        final detections = await FashionDetector.instance.detect(
          bytes,
          confidenceThreshold: 0.22,
        );
        if (!mounted) return;
        if (detections.isEmpty) {
          setState(() => _aiHint = context.tr('没有识别到明确的服装类别，可手动选择'));
          return;
        }
        final best = detections.reduce(
          (a, b) => a.confidence >= b.confidence ? a : b,
        );
        setState(() {
          _category = best.category;
          if (_name.text.trim().isEmpty) {
            _name.text = context.tr(best.displayName);
          }
          _aiHint = context.tr('本地 AI：{name} · {confidence}%', {
            'name': context.tr(best.displayName),
            'confidence': (best.confidence * 100).round(),
          });
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _aiHint = context.tr('本地 AI 暂时无法识别，可继续手动添加'));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('无法获取图片，请重试。'))));
    }
  }

  String? get _preservedDemoAsset {
    final original = widget.item;
    if (original == null ||
        original.category != _category ||
        original.color != _color) {
      return null;
    }
    return demoAssetFor(original);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = context.read<WardrobeStore>();
    final enteredName = _name.text.trim();
    final name = enteredName.isEmpty
        ? context.tr('{category} {count}', {
            'category': context.categoryLabel(_category),
            'count':
                store.items.where((i) => i.category == _category).length + 1,
          })
        : widget.item != null && enteredName == _initialDisplayName
        ? widget.item!.name
        : enteredName;
    final now = DateTime.now();
    final id = widget.item?.id ?? store.newId();

    var imagePath = _imagePath;
    var imageBase64 = _imageBase64;
    final pending = _pendingImageBytes;
    if (pending != null) {
      final saved = await store.saveImageBytes(pending, id);
      imagePath = saved.imagePath;
      imageBase64 = saved.imageBase64;
    }
    if (!mounted) return;

    final item = ClothingItem(
      id: id,
      name: name,
      category: _category,
      color: _color,
      demoAsset: _preservedDemoAsset,
      seasons: _seasons,
      brand: _brand.text.trim(),
      price: context.parseDecimal(_price.text),
      purchaseDate: _purchaseDate,
      imageBase64: imageBase64,
      imagePath: imagePath,
      notes: _notes.text.trim(),
      createdAt: widget.item?.createdAt ?? now,
    );
    store.upsertItem(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = ClothingItem(
      id: 'preview',
      name: '',
      category: _category,
      color: _color,
      demoAsset: _preservedDemoAsset,
      imageBase64: _imageBase64,
      imagePath: _imagePath,
      createdAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? context.tr('添加衣服') : context.tr('编辑衣服'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? context.tr('保存中…') : context.tr('保存')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
              children: [
                Text(
                  widget.item == null
                      ? context.tr('给喜欢的衣服，留一个位置。')
                      : context.tr('让每一件衣服，都更了解你。'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('拍张照片，补充一些细节，开启它的衣橱故事。'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: ItemThumb(preview, radius: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(context.tr('拍照')),
                    ),
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.tr('相册')),
                    ),
                    if (_imageBase64 != null || _imagePath != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _pendingImageBytes = null;
                          _imageBase64 = null;
                          _imagePath = null;
                        }),
                        child: Text(context.tr('移除照片')),
                      ),
                  ],
                ),
                if (_aiHint != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _aiHint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: context.tr('名称'),
                    hintText: context.tr('例如：白色基础T恤'),
                  ),
                ),
                _label(theme, context.tr('分类')),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in Category.values)
                      ChoiceChip(
                        avatar: Icon(c.icon, size: 16),
                        label: Text(context.categoryLabel(c)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                _label(theme, context.tr('主色')),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in kPresetColors)
                      GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c
                                  ? theme.colorScheme.primary
                                  : Colors.black12,
                              width: _color == c ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                _label(theme, context.tr('适合季节')),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in Season.values)
                      FilterChip(
                        label: Text(context.seasonLabel(s)),
                        selected: _seasons.contains(s),
                        onSelected: (v) => setState(
                          () => v ? _seasons.add(s) : _seasons.remove(s),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _brand,
                        decoration: InputDecoration(
                          labelText: context.tr('品牌（可选）'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('价格（可选）'),
                          prefixText: 'CNY ',
                          errorMaxLines: 2,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final price = context.parseDecimal(value);
                          if (price == null || !price.isFinite || price < 0) {
                            return context.tr('请输入有效的非负价格');
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    _purchaseDate == null
                        ? context.tr('购买日期（可选）')
                        : context.tr('购买于 {date}', {
                            'date': context.date(_purchaseDate!),
                          }),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && mounted) setState(() => _purchaseDate = d);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr('备注（尺码、洗护等）'),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(context.tr('保存到衣橱')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}
