import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../services/direction_service.dart';
import '../widgets/direction_icon.dart';

class CreateDirectionScreen extends StatefulWidget {
  final Direction? direction;

  const CreateDirectionScreen({super.key, this.direction});

  @override
  State<CreateDirectionScreen> createState() => _CreateDirectionScreenState();
}

class _CreateDirectionScreenState extends State<CreateDirectionScreen> {
  DirectionType? _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _actionItemsController = TextEditingController();
  final _blockersController = TextEditingController();
  final _supportIdeasController = TextEditingController();
  bool _reflectionEnabled = false;

  bool get _isEditing => widget.direction != null;

  @override
  void initState() {
    super.initState();

    final direction = widget.direction;
    if (direction != null) {
      _selectedType = direction.type;
      _titleController.text = direction.title;
      _descriptionController.text = direction.description ?? '';
      _actionItemsController.text = (direction.actionItems ?? '').isNotEmpty
          ? direction.actionItems ?? ''
          : direction.subtasks ?? '';
      _blockersController.text = direction.blockers ?? '';
      _supportIdeasController.text = direction.supportIdeas ?? '';
      _reflectionEnabled = direction.reflectionEnabled;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionItemsController.dispose();
    _blockersController.dispose();
    _supportIdeasController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _selectedType != null &&
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Direction' : 'New Direction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selection
            Text(
              'What area of life?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildTypeGrid(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Text('Title *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'e.g., Feel strong and rested',
                helperText: 'A short name for this direction',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),
            Text(
              'Description *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What do you want to achieve now or later?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),
            Text(
              'What I need to do',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actionItemsController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Small steps, tasks, or next actions',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'What is blocking or scaring me',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _blockersController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Fears, blockers, risks, or friction',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'What might help',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supportIdeasController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'People, resources, habits, or ideas',
                border: OutlineInputBorder(),
              ),
            ),

            // Examples
            if (_selectedType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Examples:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              ..._selectedType!.examples.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• "$example"',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Reflection toggle
            SwitchListTile(
              title: const Text('Enable reflection questions'),
              subtitle: const Text('Ask about this direction during check-ins'),
              value: _reflectionEnabled,
              onChanged: (value) => setState(() => _reflectionEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canCreate ? _save : null,
                child: Text(_isEditing ? 'Save' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: DirectionType.values.map((type) {
        final isSelected = _selectedType == type;
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DirectionIcon(type: type, size: 36),
                const SizedBox(height: 4),
                Text(type.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    if (!_canCreate) return;

    final direction = widget.direction;
    if (direction == null) {
      await DirectionService.instance.createDirection(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        actionItems: _actionItemsController.text.trim(),
        blockers: _blockersController.text.trim(),
        supportIdeas: _supportIdeasController.text.trim(),
        type: _selectedType!,
        reflectionEnabled: _reflectionEnabled,
      );
    } else {
      await DirectionService.instance.updateDirection(
        direction.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          subtasks: '',
          actionItems: _actionItemsController.text.trim(),
          blockers: _blockersController.text.trim(),
          supportIdeas: _supportIdeasController.text.trim(),
          type: _selectedType!,
          reflectionEnabled: _reflectionEnabled,
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
