import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../services/direction_service.dart';
import '../widgets/direction_card.dart';
import 'create_direction_screen.dart';
import 'direction_detail_screen.dart';

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({super.key});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  List<Direction> _directions = [];

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  void _loadDirections() {
    setState(() {
      _directions = DirectionService.instance.getActiveDirections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = DirectionService.instance.canAddDirection();
    final activeCount = DirectionService.instance.getActiveCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToCreate,
            ),
        ],
      ),
      body: _directions.isEmpty
          ? _buildEmptyState()
          : _buildDirectionsList(canAdd, activeCount),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🧭',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'What matters to you?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Directions help you see how your mood connects to the things you care about.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Direction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsList(bool canAdd, int activeCount) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header text
        Text(
          'Your life compass. Connect your daily check-ins to see patterns.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Direction cards
        ..._directions.map((direction) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FutureBuilder(
            future: DirectionService.instance.getStats(direction.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return DirectionCard(
                direction: direction,
                stats: snapshot.data!,
                onTap: () => _navigateToDetail(direction),
              );
            },
          ),
        )),

        // Add direction card
        if (canAdd)
          _buildAddCard(activeCount),
      ],
    );
  }

  Widget _buildAddCard(int activeCount) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _navigateToCreate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text('Add direction ($activeCount of 5)'),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDirectionScreen(),
      ),
    );

    if (result == true) {
      _loadDirections();
    }
  }

  void _navigateToDetail(Direction direction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionDetailScreen(
          direction: direction,
        ),
      ),
    );

    _loadDirections(); // Refresh in case of changes
  }
}
