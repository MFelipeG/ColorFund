import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import 'auth_service.dart';

/// Service managing goal CRUD operations against Firestore subcollection `users/{userId}/goals/{goalId}`.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('goals');
  }

  /// Real-time stream of all user goals
  Stream<List<GoalModel>> watchGoals(String userId) {
    return _goalsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  /// Add a new financial goal
  Future<void> createGoal({
    required String userId,
    required GoalModel goal,
  }) async {
    final docRef = _goalsCollection(userId).doc(goal.id);
    await docRef.set(goal.toMap());
  }

  /// Increment deposit and update the goal in Firestore
  Future<void> addDeposit({
    required String userId,
    required String goalId,
    required double depositAmount,
  }) async {
    final docRef = _goalsCollection(userId).doc(goalId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Goal does not exist');
      }

      final goal = GoalModel.fromMap(snapshot.data()!, documentId: snapshot.id);
      final newSaved = (goal.savedAmount + depositAmount).clamp(0.0, goal.targetAmount);
      final isNowCompleted = newSaved >= goal.targetAmount;

      transaction.update(docRef, {
        'savedAmount': newSaved,
        'isCompleted': isNowCompleted,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Delete a goal
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    await _goalsCollection(userId).doc(goalId).delete();
  }
}

/// Riverpod Providers for Firestore Goals
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userGoalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchGoals(user.uid);
});
