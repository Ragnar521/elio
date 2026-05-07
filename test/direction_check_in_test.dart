import 'dart:io';

import 'package:elio/models/direction.dart';
import 'package:elio/models/direction_check_in.dart';
import 'package:elio/models/direction_connection.dart';
import 'package:elio/services/direction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('elio_direction_test_');
    Hive.init(tempDir.path);
    await DirectionService.instance.init();
  });

  setUp(() async {
    await Hive.box<Direction>('directions').clear();
    await Hive.box<DirectionConnection>('direction_connections').clear();
    await Hive.box<DirectionCheckIn>('direction_check_ins').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('records multiple goal check-ins for one entry', () async {
    final malawi = await DirectionService.instance.createDirection(
      title: 'Travel to Malawi',
      description: 'Plan and save for the trip',
      type: DirectionType.growth,
      reflectionEnabled: true,
    );
    final meditation = await DirectionService.instance.createDirection(
      title: 'Start meditating',
      description: 'Build a calmer morning habit',
      type: DirectionType.peace,
      reflectionEnabled: true,
    );

    await DirectionService.instance.recordCheckIns(
      entryId: 'entry-1',
      drafts: [
        DirectionCheckInDraft(
          directionId: malawi.id,
          directionTitle: malawi.title,
          stepText: 'Checked flight prices',
          blockerText: 'Budget feels unclear',
          wantsReflection: true,
        ),
        DirectionCheckInDraft(
          directionId: meditation.id,
          directionTitle: meditation.title,
        ),
      ],
      reflectionAnswerIdsByDirectionId: {malawi.id: 'answer-1'},
    );

    final entryCheckIns = DirectionService.instance.getCheckInsForEntry(
      'entry-1',
    );
    expect(entryCheckIns, hasLength(2));
    expect(
      DirectionService.instance
          .getDirectionsForEntry('entry-1')
          .map((d) => d.id),
      containsAll([malawi.id, meditation.id]),
    );

    final malawiCheckIn = DirectionService.instance
        .getCheckInsForDirection(malawi.id)
        .single;
    expect(malawiCheckIn.hasStep, isTrue);
    expect(malawiCheckIn.hasBlocker, isTrue);
    expect(malawiCheckIn.reflectionAnswerId, 'answer-1');

    final meditationCheckIn = DirectionService.instance
        .getCheckInsForDirection(meditation.id)
        .single;
    expect(meditationCheckIn.hasStep, isFalse);
    expect(DirectionService.instance.getWeeklyCheckInCount(meditation.id), 1);
    expect(DirectionService.instance.getWeeklyProgressCount(meditation.id), 0);
  });
}
