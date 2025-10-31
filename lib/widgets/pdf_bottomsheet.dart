import 'package:flutter/material.dart';

class PdfBottomBar extends StatefulWidget {
  final String selectedTool;
  final ValueChanged<String> onSelectTool;

  const PdfBottomBar({
    super.key,
    required this.selectedTool,
    required this.onSelectTool,
  });

  @override
  State<PdfBottomBar> createState() => _PdfBottomBarState();
}

class _PdfBottomBarState extends State<PdfBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.text_fields_rounded), text: "Text"),
    Tab(icon: Icon(Icons.edit_note_rounded), text: "Signature"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            onTap: (index) {
              switch (index) {
                case 0:
                  widget.onSelectTool('highlight');
                  break;
                case 1:
                  widget.onSelectTool('text');
                  break;
                case 2:
                  widget.onSelectTool('signature');
                  break;
              }
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _buildToolContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolContent() {
    switch (widget.selectedTool) {
      case 'highlight':
        return _highlightOptions();
      case 'text':
        return _textOptions();
      case 'signature':
        return _signatureOptions();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _highlightOptions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _ColorDot(color: Colors.yellow),
          _ColorDot(color: Colors.green),
          _ColorDot(color: Colors.pinkAccent),
          _ColorDot(color: Colors.orange),
          _ColorDot(color: Colors.red),
          _ColorDot(color: Colors.blue),
          _ColorDot(color: Colors.black),
        ],
      ),
    );
  }

  Widget _textOptions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Tap on the PDF to add text.'),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorDot(color: Colors.yellow),
              _ColorDot(color: Colors.black),
              _ColorDot(color: Colors.red),
              _ColorDot(color: Colors.blue),
              _ColorDot(color: Colors.green),
              _ColorDot(color: Colors.orange),
              _ColorDot(color: Colors.pinkAccent),

            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureOptions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => widget.onSelectTool('upload_signature'),
            icon: const Icon(Icons.photo_library),
            label: const Text('Upload Signature'),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(backgroundColor: color, radius: 16);
  }
}
