import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/app_typography.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_scaffold.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  final _expenseService = ExpenseService();
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Budgets',
      currentIndex: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              color: AppColors.primary),
          onPressed: () => _selectMonth(context),
          tooltip: 'Select month',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Budget'),
        elevation: 2,
      ),
      body: StreamBuilder<List<Budget>>(
        stream: _budgetService.getBudgetsForMonth(_selectedMonth),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (budgetSnapshot.hasError) {
            return Center(child: Text('Error: ${budgetSnapshot.error}'));
          }

          final budgets = budgetSnapshot.data ?? [];

          return StreamBuilder<Map<String, double>>(
            stream: _expenseService.getMonthlySummary(_selectedMonth),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final categoryTotals = expenseSnapshot.data ?? {};

              if (budgets.isEmpty) {
                return const EmptyState(
                  icon: Icons.savings_rounded,
                  title: 'No Budgets Found',
                  message: 'Create a budget to track your spending limits.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final spent = categoryTotals[budget.category] ?? 0.0;
                  final budgetWithSpent = budget.copyWith(spent: spent);

                  return BudgetCard(
                    budget: budgetWithSpent,
                    onEdit: () =>
                        _showEditBudgetDialog(context, budgetWithSpent),
                    onDelete: () async {
                      final confirmed = await AppDialogs.showConfirm(
                        context,
                        title: 'Delete Budget',
                        message: 'Are you sure you want to delete this budget?',
                        confirmText: 'Delete',
                        icon: Icons.delete_forever_rounded,
                        confirmColor: AppColors.error,
                      );
                      if (confirmed) {
                        await _budgetService.deleteBudget(budget.id);
                      }
                    },
                  );
                },
              );
            },
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

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _BudgetFormContent(
            selectedMonth: _selectedMonth,
          ),
        ),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _BudgetFormContent(
            selectedMonth: _selectedMonth,
            budgetToEdit: budget,
          ),
        ),
      ),
    );
  }
}

class _BudgetFormContent extends StatefulWidget {
  final DateTime selectedMonth;
  final Budget? budgetToEdit;

  const _BudgetFormContent({
    required this.selectedMonth,
    this.budgetToEdit,
  });

  @override
  State<_BudgetFormContent> createState() => _BudgetFormContentState();
}

class _BudgetFormContentState extends State<_BudgetFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _budgetService = BudgetService();
  String _selectedCategory = Constants.categories.first;
  bool _isLoading = false;

  bool get _isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _amountController.text = widget.budgetToEdit!.amount.toString();
      _selectedCategory = widget.budgetToEdit!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());

      if (_isEditing) {
        final updatedBudget = widget.budgetToEdit!.copyWith(
          amount: amount,
          category: _selectedCategory,
        );
        await _budgetService.updateBudget(updatedBudget);
      } else {
        final newBudget = Budget(
          id: '',
          category: _selectedCategory,
          amount: amount,
          month: widget.selectedMonth,
        );
        await _budgetService.setBudget(newBudget);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving budget: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Edit Budget' : 'New Budget',
                  style: AppTypography.headingSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.secondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Category', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFD7CCC8))),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  items: Constants.categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: AppTypography.bodyMedium),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedCategory = newValue);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Budget Amount',
              controller: _amountController,
              hintText: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.validateAmount,
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isEditing ? 'Update Budget' : 'Create Budget',
              onPressed: _saveBudget,
              isLoading: _isLoading,
              icon: _isEditing ? Icons.check_rounded : Icons.savings_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
