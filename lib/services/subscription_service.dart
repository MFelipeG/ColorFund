import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported visual layout themes
enum GoalLayoutTheme {
  basicJar('layout_jar_01', 'Pote de Vidro Básico', isPremium: false),
  interactiveCalendar('layout_calendar_01', 'Calendário 365', isPremium: true),
  techPiggy('layout_tech_piggy', 'Cofrinho Cyber Tech', isPremium: true),
  spaceRocket('layout_space_rocket', 'Missão Espacial', isPremium: true),
  treasureChest('layout_treasure_chest', 'Baú do Tesouro', isPremium: true);

  final String id;
  final String label;
  final bool isPremium;

  const GoalLayoutTheme(this.id, this.label, {required this.isPremium});

  static GoalLayoutTheme fromId(String id) {
    return GoalLayoutTheme.values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => GoalLayoutTheme.basicJar,
    );
  }
}

/// Core domain service enforcing Freemium barriers, quota limits, and premium feature gates.
class SubscriptionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Strict maximum active goals for free users
  static const int freeTierGoalLimit = 1;

  /// Returns true if the user can create another goal based on their subscription tier
  bool canCreateNewGoal({
    required bool isPremium,
    required int currentActiveGoalsCount,
  }) {
    if (isPremium) return true;
    return currentActiveGoalsCount < freeTierGoalLimit;
  }

  /// Verifies if a given visual layout ID is unlocked for the user
  bool isLayoutUnlocked({
    required bool isPremium,
    required String layoutId,
  }) {
    final theme = GoalLayoutTheme.fromId(layoutId);
    if (!theme.isPremium) return true;
    return isPremium;
  }

  /// Gate for the Smart Calculator (automatic daily/weekly deposit planner)
  bool canUseSmartCalculator({required bool isPremium}) => isPremium;

  /// Gate for data backup & CSV/PDF export
  bool canExportData({required bool isPremium}) => isPremium;

  /// List of accessible layout themes for current tier
  List<GoalLayoutTheme> getAvailableLayouts({required bool isPremium}) {
    if (isPremium) return GoalLayoutTheme.values;
    return GoalLayoutTheme.values.where((l) => !l.isPremium).toList();
  }

  /// Real-time stream of the authenticated user's isPremium status directly from Firestore
  Stream<bool> watchUserPremiumStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      return (snapshot.data()?['isPremium'] as bool?) ?? false;
    }).handleError((_) => false);
  }
}

/// Riverpod Providers for dependency injection & reactive UI binding
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final isPremiumStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.watchUserPremiumStatus();
});

final isPremiumProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(isPremiumStreamProvider);
  return asyncValue.value ?? false;
});
