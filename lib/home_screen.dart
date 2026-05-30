import 'package:flutter/material.dart';
import 'package:expense_tracker/add_expense.dart';
import 'package:expense_tracker/add_income.dart';
import 'package:expense_tracker/expenses_tab.dart';

class HomeScreen extends StatelessWidget {
  final String loggedInUser;

  const HomeScreen({super.key, required this.loggedInUser});

  @override
  Widget build(BuildContext context) {
    final isAdmin = loggedInUser == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Expense Calculator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Hi, $loggedInUser',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ExpensesTab(),
      floatingActionButton: isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'income',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddIncomeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Income'),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'expense',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddExpenseScreen(loggedInUser: loggedInUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('Add Expense'),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ],
            )
          : FloatingActionButton.extended(
              heroTag: 'expense',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddExpenseScreen(loggedInUser: loggedInUser),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
    );
  }
}