import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String category;
  final double amount;
  final DateTime month;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    this.spent = 0,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'amount': amount,
    'month': Timestamp.fromDate(DateTime(month.year, month.month, 1)),
    'spent': spent,
  };

  factory Budget.fromJson(String id, Map<String, dynamic> json) => Budget(
    id: id,
    category: json['category'],
    amount: (json['amount'] as num).toDouble(),
    month: (json['month'] as Timestamp).toDate(),
    spent: (json['spent'] as num?)?.toDouble() ?? 0,
  );

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    DateTime? month,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      spent: spent ?? this.spent,
    );
  }
}
