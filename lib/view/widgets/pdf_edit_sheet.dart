import 'package:flutter/material.dart';

class PdfEditSheet extends StatefulWidget {
  final Color initialColor;
  final Color initialBg;
  final double initialFontSize;
  final bool initialBold;
  final bool initialItalic;
  final double initialOpacity;
  final void Function(Map<String, dynamic> cfg)? onLiveChange;

  const PdfEditSheet({
    super.key,
    required this.initialColor,
    required this.initialBg,
    required this.initialFontSize,
    required this.initialBold,
    required this.initialItalic,
    required this.initialOpacity,
    this.onLiveChange,
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _doneAsText() {
    Navigator.of(context).pop({
      'action': 'text',
      'color': _color,
      'bg': _bg,
      'fontSize': _fontSize,
      'bold': _bold,
      'italic': _italic,
      'opacity': _opacity,
    });
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
          tabs: const [
            Tab(text: 'Text'),
            Tab(text: 'Signature'),
            Tab(text: 'Comment'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Text options (colors, bg, font size)
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Color'),
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Background'),
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
                          const Text('Size:'),
                          Expanded(
                            child: Slider(
                              min: 8,
                              max: 48,
                              value: _fontSize,
                              onChanged: (v) {
                                setState(() => _fontSize = v);
                                widget.onLiveChange?.call({
                                  'action': 'text',
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
                              title: const Text('Bold'),
                              value: _bold,
                              onChanged: (v) {
                                setState(() => _bold = v ?? false);
                                widget.onLiveChange?.call({
                                  'action': 'text',
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
                              title: const Text('Italic'),
                              value: _italic,
                              onChanged: (v) {
                                setState(() => _italic = v ?? false);
                                widget.onLiveChange?.call({
                                  'action': 'text',
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
                          const Text('Opacity:'),
                          Expanded(
                            child: Slider(
                              min: 0.0,
                              max: 1.0,
                              value: _opacity,
                              onChanged: (v) {
                                setState(() => _opacity = v);
                                widget.onLiveChange?.call({
                                  'action': 'text',
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
                      label: const Text('Upload Signature'),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        'Sign on white blank paper. After uploading you can drag signature on the PDF and Save.',
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
                      'Add Hidden Comments',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      textAlign: TextAlign.center,
                      'Tap on the PDF to add a comment. A comment icon will appear. Tap the icon to view or edit your comment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _doneAsComment,
                      icon: const Icon(Icons.check),
                      label: const Text('Ready to Add Comment'),
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

  Widget _tinyDot(Color c) => GestureDetector(
    onTap: () {
      setState(() => _color = c);
      widget.onLiveChange?.call({
        'action': 'text',
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
        'action': 'text',
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
}
