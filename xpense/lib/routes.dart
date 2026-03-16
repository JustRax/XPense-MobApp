import 'package:flutter/material.dart';
import 'models/expense_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/budget/budget_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expenses/expense_add_edit_screen.dart';
import 'screens/expenses/expenses_list_screen.dart';
import 'utils/app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.expensesList:
        return MaterialPageRoute(builder: (_) => const ExpensesListScreen());
      case AppRoutes.budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
      case AppRoutes.addExpense:
        return MaterialPageRoute(builder: (_) => const ExpenseAddEditScreen());
      case AppRoutes.editExpense:
        final expense = settings.arguments as Expense?;
        return MaterialPageRoute(
          builder: (_) => ExpenseAddEditScreen(expense: expense),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }
}
