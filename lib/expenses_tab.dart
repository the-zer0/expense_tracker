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

  final List<String> members = ['All', 'Rayudu', 'Murali', 'Bhaskar'];
  final List<String> categories = [
    'All',
    'Food',
    'Travel',
    'Stay',
    'Shopping',
    'Other'
  ];

  List<QueryDocumentSnapshot> applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final matchPaidBy = filterPaidBy == null ||
          filterPaidBy == 'All' ||
          data['paidBy'] == filterPaidBy;
      final matchCategory = filterCategory == null ||
          filterCategory == 'All' ||
          data['category'] == filterCategory;
      return matchPaidBy && matchCategory;
    }).toList();
  }

  double getTotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + (data['amount'] ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No expenses added yet.'));
          }

          final filtered = applyFilters(snapshot.data!.docs);
          final total = getTotal(filtered);

          return Column(
            children: [
              // Filter Row
              Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterPaidBy ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Paid By',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: members.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => filterPaidBy = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterCategory ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => filterCategory = val),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Bar
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Total: ₹${total.toStringAsFixed(2)}  (${filtered.length} expense${filtered.length == 1 ? '' : 's'})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Expense List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No expenses match the filter.'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index].data() as Map<String, dynamic>;
                          final ts = data['timestamp'] as Timestamp?;
                          final formatted = ts != null
                              ? DateFormat('dd MMM yyyy, h:mm a').format(ts.toDate())
                              : 'Saving...';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                data['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Category: ${data['category'] ?? ''}  ·  Paid by: ${data['paidBy'] ?? ''}'),
                                  Text(
                                    formatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '₹${(data['amount'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}