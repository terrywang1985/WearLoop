import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_picker.dart';

class OutfitEditScreen extends StatefulWidget {
  const OutfitEditScreen({super.key, this.outfit, this.preselected = const []});
  final Outfit? outfit;
  final List<String> preselected;

  @override
  State<OutfitEditScreen> createState() => _OutfitEditScreenState();
}

class _OutfitEditScreenState extends State<OutfitEditScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  String? _initialDisplayName;
  bool _localizedName = false;
  late Set<String> _selected;
  late Set<String> _tags;

  @override
  void initState() {
    super.initState();
    _name.text = widget.outfit?.name ?? '';
    _note.text = widget.outfit?.note ?? '';
    _selected = {...?widget.outfit?.itemIds, ...widget.preselected};
    _tags = {...?widget.outfit?.tags};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localizedName) {
      _localizedName = true;
      if (widget.outfit case final outfit?) {
        _initialDisplayName = context.outfitName(outfit);
        _name.text = _initialDisplayName!;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.read<WardrobeStore>();
    final ids = _selected.where((id) => store.itemById(id) != null).toList()
      ..sort(
        (a, b) => store
            .itemById(a)!
            .category
            .index
            .compareTo(store.itemById(b)!.category.index),
      );
    if (ids.isEmpty) return;
    store.upsertOutfit(
      Outfit(
        id: widget.outfit?.id ?? store.newId(),
        name: _name.text.trim().isEmpty
            ? context.tr('搭配 {count}', {'count': store.outfits.length + 1})
            : widget.outfit != null && _name.text.trim() == _initialDisplayName
            ? widget.outfit!.name
            : _name.text.trim(),
        itemIds: ids,
        tags: _tags,
        favorite: widget.outfit?.favorite ?? false,
        note: _note.text.trim(),
        createdAt: widget.outfit?.createdAt ?? DateTime.now(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chosen =
        _selected.map(store.itemById).whereType<ClothingItem>().toList()
          ..sort((a, b) => a.category.index.compareTo(b.category.index));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.outfit == null ? context.tr('新建搭配') : context.tr('编辑搭配'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('把灵感，搭成日常。'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              SizedBox(
                                width: 84,
                                height: 94,
                                child: OutfitCollage(chosen),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _name,
                                  decoration: InputDecoration(
                                    labelText: context.tr('搭配名称'),
                                    hintText: context.tr('例如：周一通勤'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            context.tr('适合什么场景？'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final tag in kOutfitTags)
                                FilterChip(
                                  label: Text(context.tagLabel(tag)),
                                  selected: _tags.contains(tag),
                                  onSelected: (selected) => setState(
                                    () => selected
                                        ? _tags.add(tag)
                                        : _tags.remove(tag),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _note,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: context.tr('搭配笔记（可选）'),
                              hintText: context.tr('记下穿法、场景或一个小灵感'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        context.tr('挑选单品'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Text(
                        context.tr('已选 {count} 件', {'count': chosen.length}),
                        style: TextStyle(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: ItemPicker(
              selected: _selected,
              onChanged: (selection) => setState(() => _selected = selection),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: chosen.isEmpty ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    chosen.isEmpty
                        ? context.tr('先挑选喜欢的单品')
                        : context.tr('保存搭配 · {count} 件单品', {
                            'count': chosen.length,
                          }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
