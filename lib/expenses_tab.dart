import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String? filterPaidBy;
  String? filterCategory;
  String? filterType;

  final List<String> members = ['All', 'Rayudu', 'Murali', 'Bhaskar'];
  final List<String> categories = [
    'All',
    'Food',
    'Travel',
    'Stay',
    'Shopping',
    'Other'
  ];
  final List<String> types = ['All', 'Expense', 'Income'];

  List<QueryDocumentSnapshot> applyFilters(
      List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final docType = data['type'] ?? 'expense';

      final matchPaidBy = filterPaidBy == null ||
          filterPaidBy == 'All' ||
          data['paidBy'] == filterPaidBy ||
          data['member'] == filterPaidBy;

      final matchCategory = filterCategory == null ||
          filterCategory == 'All' ||
          data['category'] == filterCategory;

      final matchType = filterType == null ||
          filterType == 'All' ||
          (filterType == 'Income' && docType == 'income') ||
          (filterType == 'Expense' && docType != 'income');

      return matchPaidBy && matchCategory && matchType;
    }).toList();
  }

  double getTotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isIncome = data['type'] == 'income';
      final amount = (data['amount'] ?? 0.0) as double;
      return isIncome ? sum + amount : sum - amount;
    });
  }

  Map<String, double> getMemberBalances(List<QueryDocumentSnapshot> docs) {
    final Map<String, double> balances = {
      'Rayudu': 0.0,
      'Murali': 0.0,
      'Bhaskar': 0.0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0.0) as double;
      final isIncome = data['type'] == 'income';

      if (isIncome) {
        final member = data['member'] ?? '';
        if (balances.containsKey(member)) {
          balances[member] = balances[member]! + amount;
        }
      } else {
        final paidBy = data['paidBy'] ?? '';
        if (balances.containsKey(paidBy)) {
          balances[paidBy] = balances[paidBy]! - amount;
        }
      }
    }

    return balances;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }

        final allDocs = snapshot.data!.docs;
        final filtered = applyFilters(allDocs);
        final total = getTotal(allDocs);
        final balances = getMemberBalances(allDocs);

        return Column(
          children: [
            // Member Balance Cards
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Member Balances',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: balances.entries.map((entry) {
                      final isPositive = entry.value >= 0;
                      return Expanded(
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            child: Column(
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${entry.value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isPositive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Overall Total Bar
            Container(
              width: double.infinity,
              color: total >= 0 ? Colors.green[700] : Colors.red[700],
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Overall Balance: ₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Filters
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filterPaidBy ?? 'All',
                          decoration: const InputDecoration(
                            labelText: 'Person',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          items: members.map((m) {
                            return DropdownMenuItem(
                                value: m, child: Text(m));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => filterPaidBy = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filterCategory ?? 'All',
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          items: categories.map((c) {
                            return DropdownMenuItem(
                                value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => filterCategory = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filterType ?? 'All',
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          items: types.map((t) {
                            return DropdownMenuItem(
                                value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => filterType = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filtered count
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),

            // Transaction List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No transactions match the filter.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index].data()
                            as Map<String, dynamic>;
                        final isIncome = data['type'] == 'income';
                        final ts = data['timestamp'] as Timestamp?;
                        final formatted = ts != null
                            ? DateFormat('dd MMM yyyy, h:mm a')
                                .format(ts.toDate())
                            : 'Saving...';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isIncome
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  isIncome
                                      ? 'Given to: ${data['member'] ?? ''}'
                                      : 'Category: ${data['category'] ?? ''}  ·  Paid by: ${data['paidBy'] ?? ''}',
                                ),
                                Text(
                                  formatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}₹${(data['amount'] ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color:
                                    isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}