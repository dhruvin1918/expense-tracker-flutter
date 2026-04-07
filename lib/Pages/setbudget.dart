import 'package:flutter/material.dart';

class SetBudgetPage extends StatefulWidget {
  final List<String> categories;

  const SetBudgetPage({super.key, required this.categories});

  @override
  State<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Set Budget Page'),
      ),
    );
  }
}