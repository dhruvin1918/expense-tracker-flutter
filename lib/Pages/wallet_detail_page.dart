import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';

class WalletDetailPage extends StatelessWidget {
  final String walletId;
  final String walletName;

  const WalletDetailPage({
    super.key,
    required this.walletId,
    required this.walletName,
  });

  void _showActionSheet(BuildContext context, Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, tx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(
                  context,
                  tx['id'],
                  tx['wallet'],
                  tx['amount'],
                  tx['type'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> tx) {
    final amountController =
        TextEditingController(text: tx['amount'].toString());
    final descController = TextEditingController(text: tx['description']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount =
                  double.tryParse(amountController.text) ?? tx['amount'];

              await TransactionService.updateTransaction(
                transactionId: tx['id'],
                walletId: tx['wallet'],
                oldAmount: tx['amount'],
                newAmount: newAmount,
                description: descController.text,
                type: tx['type'],
              );

              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String transactionId,
    String walletId,
    double amount,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await TransactionService.deleteTransaction(
                transactionId: transactionId,
                walletId: walletId,
                amount: amount,
                type: type,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final walletRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .doc(walletId);

    return Scaffold(
      appBar: AppBar(
        title: Text(walletName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 🔹 BALANCE CARD
          StreamBuilder<DocumentSnapshot>(
            stream: walletRef.snapshots(),
            builder: (context, snapshot) {
              double balance = 0.0;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                balance = (data['balance'] ?? 0).toDouble();
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Available Balance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: balance >= 0
                                    ? Colors.green
                                    : colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          /// 🔹 TRANSACTIONS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('income')
                  .where('wallet', isEqualTo: walletId)
                  .snapshots(),
              builder: (context, incomeSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('expenses')
                      .where('wallet', isEqualTo: walletId)
                      .snapshots(),
                  builder: (context, expenseSnap) {
                    if (!incomeSnap.hasData || !expenseSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<Map<String, dynamic>> items = [
                      ...incomeSnap.data!.docs.map((d) => {
                            'id': d.id,
                            'wallet': d['wallet'],
                            'type': 'income',
                            'amount': (d['amount'] as num).toDouble(),
                            'description': d['description'] ?? '',
                            'date': (d['date'] as Timestamp).toDate(),
                          }),
                      ...expenseSnap.data!.docs.map((d) => {
                            'id': d.id,
                            'wallet': d['wallet'],
                            'type': 'expense',
                            'amount': (d['amount'] as num).toDouble(),
                            'description': d['description'] ?? '',
                            'date': (d['date'] as Timestamp).toDate(),
                          }),
                    ];

                    items.sort((a, b) => b['date'].compareTo(a['date']));

                    if (items.isEmpty) {
                      return const Center(child: Text('No transactions found'));
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final tx = items[index];
                        final isIncome = tx['type'] == 'income';

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(tx['description']),
                            subtitle: Text(
                              DateFormat.yMMMd().format(tx['date']),
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'} ₹${tx['amount'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            onLongPress: () {
                              _showActionSheet(context, tx);
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
