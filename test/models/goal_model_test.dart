import 'package:flutter_test/flutter_test.dart';
import 'package:color_fund/models/goal_model.dart';

void main() {
  group('GoalModel Unit Tests', () {
    test('Calculates normalized progress correctly', () {
      final goal = GoalModel(
        id: '1',
        title: 'Férias',
        targetAmount: 1000.0,
        savedAmount: 250.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progress, 0.25);
      expect(goal.progressPercentage, 25);
      expect(goal.remainingAmount, 750.0);
      expect(goal.isAchieved, false);
    });

    test('Clamps progress to 1.0 when saved exceeds target', () {
      final goal = GoalModel(
        id: '2',
        title: 'Notebook',
        targetAmount: 4000.0,
        savedAmount: 4500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progress, 1.0);
      expect(goal.progressPercentage, 100);
      expect(goal.remainingAmount, 0.0);
      expect(goal.isAchieved, true);
    });

    test('Handles zero target gracefully without division by zero', () {
      final goal = GoalModel(
        id: '3',
        title: 'Zero Target',
        targetAmount: 0.0,
        savedAmount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progress, 0.0);
      expect(goal.progressPercentage, 0);
      expect(goal.isAchieved, false);
    });

    test('Serialization toMap and deserialization fromMap preserve data', () {
      final now = DateTime(2026, 11, 9, 20, 0, 0);
      final original = GoalModel(
        id: 'test_id_99',
        title: 'Carro Novo',
        targetAmount: 50000.0,
        savedAmount: 15000.0,
        currency: 'BRL',
        layoutId: 'layout_tech_piggy',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final map = original.toMap();
      final restored = GoalModel.fromMap(map, documentId: 'test_id_99');

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.targetAmount, original.targetAmount);
      expect(restored.savedAmount, original.savedAmount);
      expect(restored.currency, original.currency);
      expect(restored.layoutId, original.layoutId);
    });
  });
}
