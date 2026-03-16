import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _expensesCollection =>
      _firestore.collection('expenses').doc(_userId).collection('userExpenses');

  Stream<List<Expense>> getExpensesStream() {
    if (_userId.isEmpty) return Stream.value([]);
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<List<Expense>> getExpensesByMonth(DateTime month) {
    if (_userId.isEmpty) return Stream.value([]);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<Map<String, double>> getMonthlySummary(DateTime month) {
    return getExpensesByMonth(month).map((expenses) {
      final summary = <String, double>{};
      for (var expense in expenses) {
        summary[expense.category] = (summary[expense.category] ?? 0) + expense.amount;
      }
      return summary;
    });
  }

  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.add(expense.toJson());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toJson());
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }
}
