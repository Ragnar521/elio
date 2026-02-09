import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../services/direction_service.dart';

class CreateDirectionScreen extends StatefulWidget {
  const CreateDirectionScreen({super.key});

  @override
  State<CreateDirectionScreen> createState() => _CreateDirectionScreenState();
}

class _CreateDirectionScreenState extends State<CreateDirectionScreen> {
  DirectionType? _selectedType;
  final _titleController = TextEditingController();
  bool _reflectionEnabled = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _selectedType != null && _titleController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Direction'),
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

            // Title input
            Text(
              'Describe it in your words:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'e.g., Feel strong and rested',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Examples
            if (_selectedType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Examples:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              ..._selectedType!.examples.map((example) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• "$example"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Reflection toggle
            SwitchListTile(
              title: const Text('Enable reflection questions'),
              subtitle: const Text(
                'Ask about this direction during check-ins',
              ),
              value: _reflectionEnabled,
              onChanged: (value) => setState(() => _reflectionEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canCreate ? _create : null,
                child: const Text('Create'),
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
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  type.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _create() async {
    if (!_canCreate) return;

    await DirectionService.instance.createDirection(
      title: _titleController.text.trim(),
      type: _selectedType!,
      reflectionEnabled: _reflectionEnabled,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
