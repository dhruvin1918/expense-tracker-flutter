import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:practice/Pages/addExpense.dart';
import 'package:practice/Pages/addincome.dart';
import 'package:practice/Pages/setbudget.dart';
import 'package:practice/Pages/wallet_detail_page.dart';
import 'package:practice/Toggle/switchbutton.dart';

class MyHomePage extends StatefulWidget {
  final String userName;

  const MyHomePage({super.key, required this.userName});

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
  bool _isInitialLoading = true;

  String get displayName {
    if (widget.userName.isNotEmpty) {
      return widget.userName;
    }
    return 'User';
  }

  Future<void> _refreshData(User user,
      {bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      final results = await Future.wait([
        _fetchTodayExpenses(user),
        _fetchTodayIncome(user),
        _calculateTotalBalance(user),
        _fetchWalletBalances(user),
      ]);

      final wallets = results[3] as Map<String, double>;

      if (mounted) {
        setState(() {
          _todayTotalExpense = results[0] as double;
          _todayTotalIncome = results[1] as double;
          _totalBalance = results[2] as double;
          _cashBalance = wallets['cash'] ?? 0;
          _bankBalance = wallets['bank'] ?? 0;
          _creditBalance = wallets['credit'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Dashboard refresh error: $e');
    } finally {
      if (showLoader && mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<double> _fetchTodayExpenses(User user) async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day);
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59);

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

      return total;
    } catch (e) {
      debugPrint('Expense fetch error: $e');
      return 0;
    }
  }

  Future<double> _fetchTodayIncome(User user) async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day);
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59);

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

      return total;
    } catch (e) {
      debugPrint('Income fetch error: $e');
      return 0;
    }
  }

  Future<double> _calculateTotalBalance(User user) async {
    // TODO: Replace with summary document read for scalability.
    // Suggested path: users/{uid}/summary/balance.
    try {
      final incomeSnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .get();

      final expenseSnapshot = await FirebaseFirestore
          .instance
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

      return totalIncome - totalExpense;
    } catch (e) {
      debugPrint('Balance calc error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> _fetchWalletBalances(
      User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      final wallets = <String, double>{};

      for (var doc in snapshot.docs) {
        wallets[doc.id] =
            (doc['balance'] as num?)?.toDouble() ?? 0;
      }

      return wallets;
    } catch (e) {
      debugPrint('Wallet fetch error: $e');
      return <String, double>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Please sign in to access your expense data.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // run Firestore only AFTER auth, only once
    if (!_dataLoadedOnce) {
      _dataLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData(user, showLoader: true);
      });
    }

    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final List<String> userCategories = snapshot.hasData
            ? snapshot.data!.docs
                .map((doc) => doc['name'] as String)
                .toList()
            : [];

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () => _refreshData(user),
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context)
                                .size
                                .height *
                            0.22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.brightness ==
                                    Brightness.dark
                                ? [
                                    Colors.deepPurple
                                        .shade900,
                                    Colors.blueGrey.shade700
                                  ]
                                : [
                                    const Color(0xFF6A11CB),
                                    const Color(0xFF2575FC)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight:
                                Radius.circular(25),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 25,
                        left: 20,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back,',
                              style: theme
                                  .textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '$displayName 👋',
                              style: theme
                                  .textTheme.headlineSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your financial journey starts here.',
                              style: theme
                                  .textTheme.bodyMedium
                                  ?.copyWith(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // 🔹 Total Balance
                            Text(
                              'Total Balance',
                              style: theme
                                  .textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_totalBalance.toStringAsFixed(2)}',
                              style: theme
                                  .textTheme.headlineSmall
                                  ?.copyWith(
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
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                WalletItem(
                                  walletId: 'cash',
                                  walletName: 'Cash',
                                  amount: _cashBalance,
                                  color:
                                      colorScheme.primary,
                                  onRefresh: () =>
                                      _refreshData(user),
                                ),
                                WalletItem(
                                  walletId: 'bank',
                                  walletName: 'Bank',
                                  amount: _bankBalance,
                                  color:
                                      colorScheme.secondary,
                                  onRefresh: () =>
                                      _refreshData(user),
                                ),
                                WalletItem(
                                  walletId: 'credit',
                                  walletName: 'Credit',
                                  amount: _creditBalance,
                                  color:
                                      colorScheme.tertiary,
                                  onRefresh: () =>
                                      _refreshData(user),
                                ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const Addexpense()),
                              );
                              _refreshData(user);
                            },
                            child:
                                const Text('Add Expense'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const Addincome()),
                              );
                              _refreshData(user);
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text("Today's Summary",
                                style: theme
                                    .textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .bold)),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color:
                                      Colors.green.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Income: ₹${_todayTotalIncome.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors
                                        .green.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: colorScheme.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Expense: ₹${_todayTotalExpense.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color:
                                        colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_totalBalance == 0 &&
                      _todayTotalIncome == 0 &&
                      _todayTotalExpense == 0)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No transactions yet. Add your first income or expense!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Budget Alert
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Budget Alert',
                            style: theme
                                .textTheme.titleMedium
                                ?.copyWith(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.primary,
                          foregroundColor:
                              colorScheme.onPrimary,
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SetBudgetPage(
                                      categories:
                                          userCategories),
                            ),
                          );
                        },
                        child: Text(
                          'Set Budget',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WalletItem extends StatelessWidget {
  const WalletItem({
    super.key,
    required this.walletId,
    required this.walletName,
    required this.amount,
    required this.color,
    required this.onRefresh,
  });

  final String walletId;
  final String walletName;
  final double amount;
  final Color color;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
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

        await onRefresh();
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
}
