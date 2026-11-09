import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a financial goal in the Color Fund app.
class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final String layoutId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.currency = 'BRL',
    this.layoutId = 'layout_jar_01',
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Normalized progress between 0.0 and 1.0
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Percentage integer (0 - 100)
  int get progressPercentage => (progress * 100).round();

  /// Remaining amount to achieve the goal
  double get remainingAmount {
    final remaining = targetAmount - savedAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  /// Check if goal has reached 100%
  bool get isAchieved => savedAmount >= targetAmount && targetAmount > 0;

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? currency,
    String? layoutId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      currency: currency ?? this.currency,
      layoutId: layoutId ?? this.layoutId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes GoalModel to a JSON map compatible with Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'currency': currency,
      'layoutId': layoutId,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Deserializes a Firestore DocumentSnapshot or Map into a GoalModel.
  factory GoalModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return GoalModel(
      id: documentId ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Meta Financeira',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'BRL',
      layoutId: map['layoutId'] as String? ?? 'layout_jar_01',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory GoalModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GoalModel.fromMap(data, documentId: doc.id);
  }

  @override
  String toString() {
    return 'GoalModel(id: $id, title: $title, saved: $savedAmount/$targetAmount, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel &&
        other.id == id &&
        other.title == title &&
        other.targetAmount == targetAmount &&
        other.savedAmount == savedAmount &&
        other.currency == currency &&
        other.layoutId == layoutId &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        targetAmount.hashCode ^
        savedAmount.hashCode ^
        currency.hashCode ^
        layoutId.hashCode ^
        isCompleted.hashCode;
  }
}
