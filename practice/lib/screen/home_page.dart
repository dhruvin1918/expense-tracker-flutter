import 'package:flutter/material.dart';
import 'package:practice/Pages/addExpense.dart';
import 'package:practice/Pages/addincome.dart';
import 'package:practice/Toggle/switchbutton.dart';
import 'package:practice/Pages/setbudget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:practice/Pages/wallet_detail_page.dart';

class MyHomePage extends StatefulWidget {
  final String userEmail;

  const MyHomePage({super.key, required this.userEmail});

  @override
  State<MyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage> {
  double _todayTotalExpense = 0.0;
  double _todayTotalIncome = 0.0;
  double _totalBalance = 0.0;

  double _cashBalance = 0.0;
  double _bankBalance = 0.0;
  double _creditBalance = 0.0;

  bool _dataLoadedOnce = false;

  String get displayName {
    if (widget.userEmail.isNotEmpty) {
      return widget.userEmail.split('@')[0];
    }
    return "Guest";
  }

  // 🔧 CHANGED: user passed explicitly
  void _refreshData(User user) {
    _fetchTodayExpenses(user);
    _fetchTodayIncome(user);
    _calculateTotalBalance(user);
    _fetchWalletBalances(user);
  }

  void _fetchTodayExpenses(User user) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: todayStart)
          .where('date', isLessThanOrEqualTo: todayEnd)
          .get();

      double total = 0.0;
      for (var doc in querySnapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() => _todayTotalExpense = total);
      }
    } catch (e) {
      debugPrint('Expense fetch error: $e');
    }
  }

  void _fetchTodayIncome(User user) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .where('date', isGreaterThanOrEqualTo: todayStart)
          .where('date', isLessThanOrEqualTo: todayEnd)
          .get();

      double total = 0.0;
      for (var doc in querySnapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() => _todayTotalIncome = total);
      }
    } catch (e) {
      debugPrint('Income fetch error: $e');
    }
  }

  void _calculateTotalBalance(User user) async {
    try {
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .get();

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in incomeSnapshot.docs) {
        totalIncome += (doc['amount'] as num).toDouble();
      }

      for (var doc in expenseSnapshot.docs) {
        totalExpense += (doc['amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalBalance = totalIncome - totalExpense;
        });
      }
    } catch (e) {
      debugPrint("Balance calc error: $e");
    }
  }

  void _fetchWalletBalances(User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      double cash = 0, bank = 0, credit = 0;

      for (var doc in snapshot.docs) {
        final balance = (doc['balance'] ?? 0).toDouble();

        if (doc.id == 'cash') cash = balance;
        if (doc.id == 'bank') bank = balance;
        if (doc.id == 'credit') credit = balance;
      }

      if (mounted) {
        setState(() {
          _cashBalance = cash;
          _bankBalance = bank;
          _creditBalance = credit;
        });
      }
    } catch (e) {
      debugPrint('Wallet fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // run Firestore only AFTER auth, only once
    if (user != null && !_dataLoadedOnce) {
      _dataLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData(user);
      });
    }
    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('categories')
              .orderBy('timestamp', descending: true)
              .snapshots()
          : Stream<QuerySnapshot>.empty(),
      builder: (context, snapshot) {
        final List<String> userCategories = snapshot.hasData
            ? snapshot.data!.docs.map((doc) => doc['name'] as String).toList()
            : [];

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    Container(
                      height: 190,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.brightness == Brightness.dark
                              ? [
                                  Colors.deepPurple.shade900,
                                  Colors.blueGrey.shade700
                                ]
                              : [
                                  const Color(0xFF6A11CB),
                                  const Color(0xFF2575FC)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back,',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$displayName 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your financial journey starts here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Total Balance Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Total Balance
                          Text(
                            'Total Balance',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_totalBalance.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _totalBalance >= 0
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Divider(),

                          // 🔹 Wallets Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _walletItem(context, 'cash', 'Cash', _cashBalance,
                                  Colors.green, user, _refreshData),
                              _walletItem(context, 'bank', 'Bank', _bankBalance,
                                  Colors.blue, user, _refreshData),
                              _walletItem(
                                  context,
                                  'credit',
                                  'Credit',
                                  _creditBalance,
                                  Colors.deepPurple,
                                  user,
                                  _refreshData),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Expense / Income Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Addexpense()),
                            );
                            if (user != null) _refreshData(user);
                          },
                          child: const Text('Add Expense'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Addincome()),
                            );
                            if (user != null) _refreshData(user);
                          },
                          child: const Text('Add Income'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Today's Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Summary",
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 20),
                          Text(
                              'Income: ₹${_todayTotalIncome.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green)),
                          Text(
                              'Expense: ₹${_todayTotalExpense.toStringAsFixed(2)}',
                              style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Budget Alert
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Budget Alert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Switchbutton(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Set Budget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SetBudgetPage(categories: userCategories),
                          ),
                        );
                      },
                      child: const Text(
                        'Set Budget',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _walletItem(
  BuildContext context,
  String walletId, // cash / bank / credit
  String walletName, // Cash / Bank / Credit
  double amount,
  Color color,
  User? user,
  Function(User) onRefresh,
) {
  IconData icon;

  switch (walletId.toLowerCase()) {
    case 'cash':
      icon = Icons.money;
      break;
    case 'bank':
      icon = Icons.account_balance;
      break;
    case 'credit':
      icon = Icons.credit_card;
      break;
    default:
      icon = Icons.wallet;
  }

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletDetailPage(
            walletId: walletId,
            walletName: walletName,
          ),
        ),
      );

      if (user != null) {
        onRefresh(user);
      }
    },
    child: Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          walletName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
