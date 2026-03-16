import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _budgetsCollection =>
      _firestore.collection('budgets').doc(_userId).collection('userBudgets');

  Future<void> setBudget(Budget budget) async {
    final startOfMonth = DateTime(budget.month.year, budget.month.month, 1);
    
    // Check if budget for this category and month already exists
    final query = await _budgetsCollection
        .where('category', isEqualTo: budget.category)
        .where('month', isEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    if (query.docs.isNotEmpty) {
      await updateBudget(budget.copyWith(id: query.docs.first.id));
    } else {
      await _budgetsCollection.add(budget.toJson());
    }
  }

  Future<void> updateBudget(Budget budget) async {
    await _budgetsCollection.doc(budget.id).update(budget.toJson());
  }

  Future<void> deleteBudget(String budgetId) async {
    await _budgetsCollection.doc(budgetId).delete();
  }

  Stream<List<Budget>> getBudgetsForMonth(DateTime month) {
    if (_userId.isEmpty) return Stream.value([]);
    final startOfMonth = DateTime(month.year, month.month, 1);

    return _budgetsCollection
        .where('month', isEqualTo: Timestamp.fromDate(startOfMonth))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Budget.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
