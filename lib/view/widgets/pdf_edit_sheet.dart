import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/local_controller.dart';

class PdfEditSheet extends StatefulWidget {
  final Color initialColor;
  final Color initialBg;
  final double initialFontSize;
  final bool initialBold;
  final bool initialItalic;
  final double initialOpacity;
  final void Function(Map<String, dynamic> cfg)? onLiveChange;
  final bool showTextOptions;
  final String initialText;
  final bool showTextInput;

  PdfEditSheet({
    super.key,
    required this.initialColor,
    required this.initialBg,
    required this.initialFontSize,
    required this.initialBold,
    required this.initialItalic,
    required this.initialOpacity,
    this.onLiveChange,
    this.showTextOptions = true,
    this.initialText = '',
    this.showTextInput = true,
  });

  @override
  State<PdfEditSheet> createState() => _PdfEditSheetState();
}

class _PdfEditSheetState extends State<PdfEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _color = Colors.black;
  Color _bg = Colors.transparent;
  double _fontSize = 18;
  bool _bold = false;
  bool _italic = false;
  double _opacity = 1.0;
  final lc = Get.find<LocaleController>();
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _color = widget.initialColor;
    _bg = widget.initialBg;
    _fontSize = widget.initialFontSize;
    _bold = widget.initialBold;
    _italic = widget.initialItalic;
    _opacity = widget.initialOpacity;
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _tinyDot(Color c) => GestureDetector(
    onTap: () {
      setState(() => _color = c);
      widget.onLiveChange?.call({
        'action': lc.t('text'),
        'color': _color,
        'bg': _bg,
        'fontSize': _fontSize,
        'bold': _bold,
        'italic': _italic,
        'opacity': _opacity,
      });
    },
    child: CircleAvatar(
      backgroundColor: c,
      radius: 16,
      child: _color == c
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    ),
  );

  Widget _tinyBg(Color c) => GestureDetector(
    onTap: () {
      setState(() => _bg = c);
      widget.onLiveChange?.call({
        'action': lc.t('text'),
        'color': _color,
        'bg': _bg,
        'fontSize': _fontSize,
        'bold': _bold,
        'italic': _italic,
        'opacity': _opacity,
      });
    },
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _bg == c ? const Icon(Icons.check, size: 16) : null,
    ),
  );

  void _doneAsText() {
    final result = <String, dynamic>{
      'action': lc.t('text'),
      'color': _color,
      'bg': _bg,
      'fontSize': _fontSize,
      'bold': _bold,
      'italic': _italic,
      'opacity': _opacity,
    };
    if (widget.showTextInput) {
      result['textValue'] = _textController.text;
    }
    Navigator.of(context).pop(result);
  }

  void _doneAsSignature() {
    Navigator.of(context).pop({'action': 'signature'});
  }

  void _doneAsComment() {
    Navigator.of(context).pop({'action': 'comment'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header with close/check
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // confirm based on active tab
                  if (_tabController.index == 0) {
                    _doneAsText();
                  } else if (_tabController.index == 1) {
                    _doneAsSignature();
                  } else {
                    // Comments tab
                    Navigator.of(context).pop({'action': 'comment'});
                  }
                },
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ),

        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: lc.t('text')),
            Tab(text: lc.t('signature')),
            Tab(text: lc.t('comment')),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Text tab: simplified or full options depending on showTextOptions
              widget.showTextOptions
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (widget.showTextInput) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(lc.t('addText')),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  hintText: lc.t('typeText'),
                                ),
                                onChanged: (v) {
                                  widget.onLiveChange?.call({
                                    'action': lc.t('text'),
                                    'textValue': v,
                                    'color': _color,
                                    'bg': _bg,
                                    'fontSize': _fontSize,
                                    'bold': _bold,
                                    'italic': _italic,
                                    'opacity': _opacity,
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(lc.t('color')),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _tinyDot(Colors.black),
                                _tinyDot(Colors.red),
                                _tinyDot(Colors.blue),
                                _tinyDot(Colors.green),
                                _tinyDot(Colors.orange),
                                _tinyDot(Colors.purple),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(lc.t('background')),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _tinyBg(Colors.transparent),
                                _tinyBg(Colors.yellow),
                                _tinyBg(Colors.orange),
                                _tinyBg(Colors.pink),
                                _tinyBg(Colors.lightGreen),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(lc.t('size' + ':')),
                                Expanded(
                                  child: Slider(
                                    min: 8,
                                    max: 48,
                                    value: _fontSize,
                                    onChanged: (v) {
                                      setState(() => _fontSize = v);
                                      widget.onLiveChange?.call({
                                        'action': lc.t('text'),
                                        'color': _color,
                                        'bg': _bg,
                                        'fontSize': _fontSize,
                                        'bold': _bold,
                                        'italic': _italic,
                                        'opacity': _opacity,
                                      });
                                    },
                                  ),
                                ),
                                Text('${_fontSize.toInt()}pt'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(lc.t('bold')),
                                    value: _bold,
                                    onChanged: (v) {
                                      setState(() => _bold = v ?? false);
                                      widget.onLiveChange?.call({
                                        'action': lc.t('text'),
                                        'color': _color,
                                        'bg': _bg,
                                        'fontSize': _fontSize,
                                        'bold': _bold,
                                        'italic': _italic,
                                        'opacity': _opacity,
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(lc.t('italic')),
                                    value: _italic,
                                    onChanged: (v) {
                                      setState(() => _italic = v ?? false);
                                      widget.onLiveChange?.call({
                                        'action': lc.t('text'),
                                        'color': _color,
                                        'bg': _bg,
                                        'fontSize': _fontSize,
                                        'bold': _bold,
                                        'italic': _italic,
                                        'opacity': _opacity,
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(lc.t('opacity' + ':')),
                                Expanded(
                                  child: Slider(
                                    min: 0.0,
                                    max: 1.0,
                                    value: _opacity,
                                    onChanged: (v) {
                                      setState(() => _opacity = v);
                                      widget.onLiveChange?.call({
                                        'action': lc.t('text'),
                                        'color': _color,
                                        'bg': _bg,
                                        'fontSize': _fontSize,
                                        'bold': _bold,
                                        'italic': _italic,
                                        'opacity': _opacity,
                                      });
                                    },
                                  ),
                                ),
                                Text('${(_opacity * 100).toInt()}%'),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Spacer(),
                          Icon(
                            Icons.text_fields,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lc.t('textInstructions'),
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _doneAsText,
                            icon: const Icon(Icons.check),
                            label: Text(lc.t('readyText')),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

              // Signature tab: only upload button (sheet will return 'signature' on Done)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _doneAsSignature,
                      icon: const Icon(Icons.photo_library),
                      label: Text(lc.t('uploadSignature')),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        lc.t('signInstructions'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Comment tab: instructions for adding comments
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.comment,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lc.t('addComments'),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _doneAsComment,
                      icon: const Icon(Icons.check),
                      label: Text(lc.t('readyComment')),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
