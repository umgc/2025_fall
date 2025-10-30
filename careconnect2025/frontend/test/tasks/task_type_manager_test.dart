import 'dart:convert';

import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskTypeManager', () {
    late TaskTypeManager manager;

    setUp(() async {
      // Reset SharedPreferences mock before each test
      SharedPreferences.setMockInitialValues({});
      manager = TaskTypeManager();
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test('loads default task types when no prefs exist', () async {
      final keys = manager.getSortedTypes();

      expect(keys, contains('medication'));
      expect(manager.getIcon('appointment'), Icons.event);
      //  Compare by value to avoid MaterialColor vs Color mismatch
      expect(manager.getColor('exercise').value, Colors.green.value);
    });

    test('addTaskType adds a new entry and persists it', () async {
      await manager.addTaskType(
        'hydration',
        Colors.blueGrey,
        icon: Icons.water_drop,
      );

      expect(manager.taskTypeColors.containsKey('hydration'), true);
      expect(manager.getIcon('hydration'), Icons.water_drop);
      expect(manager.getColor('hydration').value, Colors.blueGrey.value);

      //  Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('task_type_settings');
      expect(jsonStr, isNotNull);

      final decoded = json.decode(jsonStr!);
      expect(decoded.containsKey('hydration'), true);
    });

    test('removeTaskType removes and updates prefs', () async {
      await manager.addTaskType('test', Colors.cyan);
      expect(manager.taskTypeColors.containsKey('test'), true);

      await manager.removeTaskType('test');
      expect(manager.taskTypeColors.containsKey('test'), false);

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('task_type_settings');
      final decoded = json.decode(jsonStr!);
      expect(decoded.containsKey('test'), false);
    });

    test('updateTaskColor changes color and persists it', () async {
      await manager.addTaskType('therapy', Colors.amber);
      expect(manager.getColor('therapy').value, Colors.amber.value);

      await manager.updateTaskColor('therapy', Colors.purple);
      expect(manager.getColor('therapy').value, Colors.purple.value);

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('task_type_settings');
      final decoded = json.decode(jsonStr!);
      expect(decoded['therapy']['color'], Colors.purple.value);
    });

    test('updateTaskIcon changes icon and persists it', () async {
      await manager.addTaskType('monitoring', Colors.red);
      expect(manager.getIcon('monitoring'), Icons.task);

      await manager.updateTaskIcon('monitoring', Icons.health_and_safety);
      expect(manager.getIcon('monitoring'), Icons.health_and_safety);

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('task_type_settings');
      final decoded = json.decode(jsonStr!);
      expect(decoded['monitoring']['icon'], Icons.health_and_safety.codePoint);
    });

    test('resetDefaults restores all predefined types', () async {
      await manager.addTaskType('custom', Colors.black);
      expect(manager.taskTypeColors.containsKey('custom'), true);

      await manager.resetDefaults();
      expect(manager.taskTypeColors.containsKey('custom'), false);
      expect(manager.taskTypeColors.containsKey('medication'), true);
    });

    test('getColor and getIcon return fallback for unknown types', () async {
      expect(manager.getColor('unknown').value, Colors.deepOrange.value);
      expect(manager.getIcon('unknown'), Icons.task);
    });

    test('getSortedTypes returns sorted list', () async {
      await manager.addTaskType('Zeta', Colors.purple);
      await manager.addTaskType('Alpha', Colors.red);

      final sorted = manager.getSortedTypes();
      expect(sorted.first, 'alpha');
      expect(sorted.last, 'zeta');
    });

    test(
      'persistence works: data is reloaded from SharedPreferences',
      () async {
        // Simulate stored data in prefs
        final prefs = await SharedPreferences.getInstance();
        final encoded = json.encode({
          'hydration': {
            'color': Colors.blue.value,
            'icon': Icons.water_drop.codePoint,
          },
        });
        await prefs.setString('task_type_settings', encoded);

        // Create a new manager → should auto-load hydration
        final manager2 = TaskTypeManager();
        await Future.delayed(const Duration(milliseconds: 10));

        //  Compare by color value
        expect(manager2.getColor('hydration').value, Colors.blue.value);
        expect(manager2.getIcon('hydration'), Icons.water_drop);
      },
    );
  });
}
