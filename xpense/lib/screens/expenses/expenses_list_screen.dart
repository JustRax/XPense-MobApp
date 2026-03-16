import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../screens/expenses/expense_add_edit_screen.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/monthly_summary_card.dart';
import '../../widgets/responsive_scaffold.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();
  String _selectedCategory = 'All';
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Expenses',
      currentIndex: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              color: AppColors.primary),
          onPressed: () => _selectMonth(context),
          tooltip: 'Select month',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExpenseAddEditScreen.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
        elevation: 2,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpensesByMonth(_selectedMonth),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allExpenses = snapshot.data ?? [];
          final filteredExpenses = _selectedCategory == 'All'
              ? allExpenses
              : allExpenses.where((e) => e.category == _selectedCategory).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<List<Budget>>(
                    stream: _budgetService.getBudgetsForMonth(_selectedMonth),
                    builder: (context, budgetSnapshot) {
                      final totalBudget = (budgetSnapshot.data ?? [])
                          .fold(0.0, (sum, b) => sum + b.amount);

                      return StreamBuilder<Map<String, double>>(
                        stream: _expenseService.getMonthlySummary(_selectedMonth),
                        builder: (context, summarySnapshot) {
                          final categoryTotals = summarySnapshot.data ?? {};
                          final totalSpent = categoryTotals.values
                              .fold(0.0, (a, b) => a + b);

                          return MonthlySummaryCard(
                            categoryTotals: categoryTotals,
                            totalSpent: totalSpent,
                            totalBudget: totalBudget > 0 ? totalBudget : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      CategoryChip(
                        category: 'All',
                        isSelected: _selectedCategory == 'All',
                        onSelected: (cat) => setState(() => _selectedCategory = cat),
                      ),
                      const SizedBox(width: 8),
                      ...Constants.categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryChip(
                              category: category,
                              isSelected: _selectedCategory == category,
                              onSelected: (cat) => setState(() => _selectedCategory = cat),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              if (filteredExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Expenses Found',
                    message: _selectedCategory == 'All'
                        ? 'You haven\'t added any expenses for this month yet.'
                        : 'No expenses found for $_selectedCategory this month.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = filteredExpenses[index];
                        return Dismissible(
                          key: Key(expense.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 52, height: 52,
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Delete Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 8),
                                        const Text('Are you sure you want to delete this expense?', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  side: const BorderSide(color: Color(0xFFD7CCC8)),
                                                ),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.error,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 0,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            _expenseService.deleteExpense(expense.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Expense deleted'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: ExpenseCard(
                            expense: expense,
                            onTap: () => ExpenseAddEditScreen.show(
                              context,
                              expense: expense,
                            ),
                            onDelete: () async {
                              final confirmed = await AppDialogs.showConfirm(
                                context,
                                title: 'Delete Expense',
                                message: 'Are you sure you want to delete this expense?',
                                confirmText: 'Delete',
                                icon: Icons.delete_forever_rounded,
                                confirmColor: AppColors.error,
                              );
                              if (confirmed) {
                                _expenseService.deleteExpense(expense.id);
                              }
                            },
                          ),
                        );
                      },
                      childCount: filteredExpenses.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80), // Padding for FAB
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
    }
  }
}
