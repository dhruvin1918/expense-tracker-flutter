import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );

    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletSnap = await transaction.get(walletRef);
        final currentBalance = (walletSnap.data()?['balance'] ?? 0).toDouble();

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    InputDecoration fieldDecoration(String label) {
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
                  decoration: fieldDecoration('Amount').copyWith(
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
                  decoration: fieldDecoration('Payment Source'),
                  dropdownColor: colorScheme.surface,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(
                        value: 'credit', child: Text('Credit Card')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedWallet = value!),
                ),

                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: fieldDecoration('Description'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter description'
                      : null,
                ),

                const SizedBox(height: 20),

                // Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                    onPressed: _saveIncome,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Save Income',
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
