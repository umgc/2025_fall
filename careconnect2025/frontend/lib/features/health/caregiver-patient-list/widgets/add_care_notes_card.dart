import 'package:flutter/material.dart';

class AddCareNoteCard extends StatefulWidget {
  final void Function(String type, String body)? onAdd;
  const AddCareNoteCard({super.key, this.onAdd});

  @override
  State<AddCareNoteCard> createState() => _AddCareNoteCardState();
}

class _AddCareNoteCardState extends State<AddCareNoteCard> {
  final _controller = TextEditingController();
  String _selectedType = 'general';
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note before adding.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 400)); // simulate API

      widget.onAdd?.call(_selectedType, text);
      _controller.clear();

      FocusManager.instance.primaryFocus?.unfocus();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = cs.outlineVariant.withValues(alpha: .35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.add_comment_outlined, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Add Care Note', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),

          // Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('general', 'General', selectedBg: cs.primary, selectedFg: cs.onPrimary),
              _pill('assessment', 'Assessment',
                  selectedBg: cs.primary.withValues(alpha: .15), selectedFg: cs.primary),
              _pill('medication', 'Medication',
                  selectedBg: Colors.amber.withValues(alpha: .9), selectedFg: Colors.black87),
              _pill('urgent', 'Urgent', selectedBg: cs.error, selectedFg: cs.onError),
            ],
          ),
          const SizedBox(height: 12),

          // Input (use surfaceContainerHighest instead of surfaceVariant)
          TextField(
            controller: _controller,
            enabled: !_isPosting,
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _handleAdd(),
            decoration: InputDecoration(
              hintText: 'Enter your care note here...',
              filled: true,

              fillColor: cs.surfaceContainerHighest.withValues(alpha: .15),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Full-width button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _isPosting ? null : _handleAdd,
              icon: _isPosting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isPosting ? 'Adding...' : 'Add Note'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
      String value,
      String label, {
        required Color selectedBg,
        required Color selectedFg,
      }) {
    final cs = Theme.of(context).colorScheme;
    final bool selected = _selectedType == value;

    final Color bg = selected
        ? selectedBg

        : cs.surfaceContainerHighest.withValues(alpha: .35);
    final Color fg = selected
        ? selectedFg
        : cs.onSurface.withValues(alpha: .85);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _isPosting ? null : () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? selectedBg : cs.outlineVariant.withValues(alpha: .35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
