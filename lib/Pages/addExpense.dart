import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Addexpense extends StatefulWidget {
  const Addexpense({super.key});

  @override
  State<Addexpense> createState() => _AddexpenseState();
}

class _AddexpenseState extends State<Addexpense> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _selectedWallet = 'cash';
  DateTime _selectedDate = DateTime.now();
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .orderBy('timestamp')
          .get();

      if (mounted) {
        setState(() {
          _categories = snapshot.docs.map((d) => d['name'] as String).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Category fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final expenseAmount = double.parse(_amountController.text);

      final walletRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_selectedWallet);

      final expenseRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc();

      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(); // <-- create doc reference

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletSnap = await transaction.get(walletRef);

        final currentBalance =
            walletSnap.exists ? (walletSnap['balance'] ?? 0).toDouble() : 0.0;

        // Optional safety check
        if (currentBalance < expenseAmount) {
          throw Exception('Insufficient balance');
        }

        transaction.set(
          walletRef,
          {
            'balance': currentBalance - expenseAmount,
          },
          SetOptions(merge: true),
        );

        transaction.set(expenseRef, {
          'amount': expenseAmount,
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'wallet': _selectedWallet,
          'date': Timestamp.fromDate(_selectedDate),
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.set(transactionRef, {
          'type': 'expense',
          'amount': expenseAmount,
          'description': _descriptionController.text.trim(),
          'wallet': _selectedWallet,
          'date': Timestamp.fromDate(_selectedDate),
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense added successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Log Your Expense'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(context, 'Amount')
                            .copyWith(prefixText: '₹ '),
                        validator: (v) {
                          if (v == null ||
                              double.tryParse(v) == null ||
                              double.parse(v) <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _fieldDecoration(context, 'Category'),
                        items: _categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) => v == null ? 'Select category' : null,
                      ),

                      const SizedBox(height: 20),

                      // Wallet
                      DropdownButtonFormField<String>(
                        value: _selectedWallet,
                        decoration: _fieldDecoration(context, 'Payment Source'),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'bank', child: Text('Bank')),
                          DropdownMenuItem(
                              value: 'credit', child: Text('Credit Card')),
                        ],
                        onChanged: (v) => setState(() => _selectedWallet = v!),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _fieldDecoration(context, 'Description'),
                      ),

                      const SizedBox(height: 20),

                      // Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${DateFormat.yMd().format(_selectedDate)}',
                          ),
                          TextButton.icon(
                            onPressed: _presentDatePicker,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Select Date'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveExpense,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Save Expense',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
