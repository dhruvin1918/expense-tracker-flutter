import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Addincome extends StatefulWidget {
  const Addincome({super.key});

  @override
  State<Addincome> createState() => _AddincomeState();
}

class _AddincomeState extends State<Addincome> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedWallet = 'cash';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate =
        DateTime(now.year - 5, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please sign in before adding income.')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      final amount = double.parse(_amountController.text);

      final walletRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_selectedWallet);

      final incomeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .doc();

      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(); // <-- create doc reference

      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final walletSnap = await transaction.get(walletRef);
        final currentBalance =
            (walletSnap.data()?['balance'] ?? 0).toDouble();

        transaction.set(
          walletRef,
          {'balance': currentBalance + amount},
          SetOptions(merge: true),
        );

        transaction.set(incomeRef, {
          'amount': amount,
          'description': _descriptionController.text.trim(),
          'wallet': _selectedWallet,
          'date': Timestamp.fromDate(_selectedDate),
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.set(transactionRef, {
          'type': 'income',
          'amount': amount,
          'description': _descriptionController.text.trim(),
          'wallet': _selectedWallet,
          'date': Timestamp.fromDate(_selectedDate),
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Income added successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Income save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to save income. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _fieldDecoration(
      BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest
          .withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Log Your Income'),
        centerTitle: true,
      ),
      body: Padding(
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration:
                      _fieldDecoration(context, 'Amount')
                          .copyWith(
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    if (value == null ||
                        double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Wallet
                DropdownButtonFormField<String>(
                  value: _selectedWallet,
                  decoration: _fieldDecoration(
                      context, 'Payment Source'),
                  dropdownColor: colorScheme.surface,
                  items: const [
                    DropdownMenuItem(
                        value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                        value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(
                        value: 'credit',
                        child: Text('Credit Card')),
                  ],
                  onChanged: (value) => setState(
                      () => _selectedWallet = value!),
                ),

                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 100,
                  decoration: _fieldDecoration(
                      context, 'Description'),
                ),

                const SizedBox(height: 20),

                // Date
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${DateFormat.yMd().format(_selectedDate)}',
                      ),
                      TextButton.icon(
                        onPressed: _presentDatePicker,
                        icon: const Icon(
                            Icons.calendar_today),
                        label: const Text('Select Date'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSaving ? null : _saveIncome,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Income',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold),
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
