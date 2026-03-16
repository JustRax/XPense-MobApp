import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_typography.dart';
import '../../screens/expenses/expense_add_edit_screen.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/monthly_summary_card.dart';
import '../../widgets/responsive_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _expenseService = ExpenseService();
  final _budgetService = BudgetService();
  final _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExpenseAddEditScreen.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Budget>>(
              stream: _budgetService.getBudgetsForMonth(_currentMonth),
              builder: (context, budgetSnap) {
                final totalBudget = (budgetSnap.data ?? [])
                    .fold(0.0, (a, b) => a + b.amount);

                return StreamBuilder<Map<String, double>>(
                  stream: _expenseService.getMonthlySummary(_currentMonth),
                  builder: (context, snapshot) {
                    final categoryTotals = snapshot.data ?? {};
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Expenses', style: AppTypography.headingMedium),
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.expensesList),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'See All',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Expense>>(
              stream: _expenseService.getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }

                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No expenses yet',
                    message: 'Add your first expense to see it here.',
                  );
                }

                final recentExpenses = expenses.take(5).toList();
                return Column(
                  children: recentExpenses
                      .map((expense) => ExpenseCard(
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
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budgets', style: AppTypography.headingMedium),
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.budget),
                  icon: const Icon(Icons.tune_rounded,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'Manage',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Budget>>(
              stream: _budgetService.getBudgetsForMonth(_currentMonth),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }

                return StreamBuilder<Map<String, double>>(
                  stream:
                      _expenseService.getMonthlySummary(_currentMonth),
                  builder: (context, expenseSnapshot) {
                    final budgets = budgetSnapshot.data ?? [];
                    final categoryTotals = expenseSnapshot.data ?? {};

                    if (budgets.isEmpty) {
                      return const EmptyState(
                        icon: Icons.savings_rounded,
                        title: 'No budgets set',
                        message:
                            'Set limits to keep your spending on track.',
                      );
                    }

                    final topBudgets = budgets.take(3).toList();
                    return Column(
                      children: topBudgets.map((budget) {
                        final spent =
                            categoryTotals[budget.category] ?? 0.0;
                        final budgetWithSpent =
                            budget.copyWith(spent: spent);
                        return BudgetCard(
                          budget: budgetWithSpent,
                          onEdit: () => _showEditBudgetDialog(
                              context, budgetWithSpent),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    final amountController =
        TextEditingController(text: budget.amount.toString());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Budget',
                            style: AppTypography.headingSmall),
                        Text(budget.category,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    labelStyle:
                        AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    prefixIcon: const Icon(Icons.attach_money_rounded,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFD7CCC8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFD7CCC8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side:
                              const BorderSide(color: Color(0xFFD7CCC8)),
                        ),
                        child: Text('Cancel',
                            style: AppTypography.labelMedium
                                .copyWith(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount =
                              double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            final updated = budget.copyWith(amount: amount);
                            await BudgetService().updateBudget(updated);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Save',
                            style: AppTypography.labelMedium
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
