import 'package:flutter_test/flutter_test.dart';
import 'package:color_fund/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService Business Rules QA Tests', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('Free tier allows only 1 active goal', () {
      // 0 active goals -> can create
      expect(
        service.canCreateNewGoal(isPremium: false, currentActiveGoalsCount: 0),
        isTrue,
      );

      // 1 active goal -> blocked
      expect(
        service.canCreateNewGoal(isPremium: false, currentActiveGoalsCount: 1),
        isFalse,
      );

      // 2 active goals -> blocked
      expect(
        service.canCreateNewGoal(isPremium: false, currentActiveGoalsCount: 2),
        isFalse,
      );
    });

    test('Premium tier allows unlimited active goals', () {
      expect(
        service.canCreateNewGoal(isPremium: true, currentActiveGoalsCount: 0),
        isTrue,
      );
      expect(
        service.canCreateNewGoal(isPremium: true, currentActiveGoalsCount: 1),
        isTrue,
      );
      expect(
        service.canCreateNewGoal(isPremium: true, currentActiveGoalsCount: 15),
        isTrue,
      );
    });

    test('Layout unlock validation enforces Freemium barriers', () {
      // Basic Jar is unlocked for everyone
      expect(
        service.isLayoutUnlocked(
          isPremium: false,
          layoutId: GoalLayoutTheme.basicJar.id,
        ),
        isTrue,
      );
      expect(
        service.isLayoutUnlocked(
          isPremium: true,
          layoutId: GoalLayoutTheme.basicJar.id,
        ),
        isTrue,
      );

      // Premium layouts are locked for Free users
      expect(
        service.isLayoutUnlocked(
          isPremium: false,
          layoutId: GoalLayoutTheme.interactiveCalendar.id,
        ),
        isFalse,
      );
      expect(
        service.isLayoutUnlocked(
          isPremium: false,
          layoutId: GoalLayoutTheme.techPiggy.id,
        ),
        isFalse,
      );
      expect(
        service.isLayoutUnlocked(
          isPremium: false,
          layoutId: GoalLayoutTheme.spaceRocket.id,
        ),
        isFalse,
      );

      // Premium layouts are unlocked for Pro users
      expect(
        service.isLayoutUnlocked(
          isPremium: true,
          layoutId: GoalLayoutTheme.spaceRocket.id,
        ),
        isTrue,
      );
    });

    test('Smart Calculator and Data Export are locked for Free tier', () {
      expect(service.canUseSmartCalculator(isPremium: false), isFalse);
      expect(service.canUseSmartCalculator(isPremium: true), isTrue);

      expect(service.canExportData(isPremium: false), isFalse);
      expect(service.canExportData(isPremium: true), isTrue);
    });
  });
}
