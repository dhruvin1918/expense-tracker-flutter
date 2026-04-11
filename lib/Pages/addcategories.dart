import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Addcategories extends StatefulWidget {
  const Addcategories({super.key});

  @override
  State<Addcategories> createState() =>
      _AddcategoriesState();
}

class _AddcategoriesState extends State<Addcategories> {
  final TextEditingController _categoryController =
      TextEditingController();
  bool _isAdding = false;

  String _normalizeCategoryName(String input) {
    final text = input.trim();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() +
        text.substring(1).toLowerCase();
  }

  Future<void> _addCategory() async {
    if (_isAdding) return;

    final user = FirebaseAuth.instance.currentUser;
    final normalized =
        _normalizeCategoryName(_categoryController.text);

    if (user == null || normalized.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      final categoriesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories');

      final existing = await categoriesRef
          .where('name', isEqualTo: normalized)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category already exists.'),
          ),
        );
        return;
      }

      await categoriesRef.add({
        'name': normalized,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _categoryController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully.'),
        ),
      );
    } catch (e) {
      debugPrint('Add category error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to add category. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteCategory(
      String docId, String categoryName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '"$categoryName" will be removed. Existing expenses using this category will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$categoryName" deleted.')),
      );
    } catch (e) {
      debugPrint('Delete category error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to delete category. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Add Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    maxLength: 30,
                    style: TextStyle(
                        color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter category name',
                      hintStyle: TextStyle(
                          color: colorScheme.outline),
                      filled: true,
                      fillColor: colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(Icons.category,
                          color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: IconButton(
                    icon: _isAdding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(Icons.add,
                            color: colorScheme.onPrimary),
                    onPressed:
                        _isAdding ? null : _addCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Categories',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: user == null
                  ? const Center(
                      child: Text(
                          '⚠️ Please sign in to add categories.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('categories')
                          .orderBy('timestamp',
                              descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child:
                                  CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                                '❌ Error loading categories.'),
                          );
                        }

                        final docs =
                            snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No categories added yet.\nTap + to add one!',
                              textAlign: TextAlign.center,
                              style: theme
                                  .textTheme.bodyMedium
                                  ?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];

                            final categoryName = (doc.data()
                                        as Map<String,
                                            dynamic>?)?[
                                    'name'] ??
                                'Unnamed';

                            return Card(
                              color: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              elevation: 3,
                              child: ListTile(
                                leading: Icon(
                                    Icons.category,
                                    color: colorScheme
                                        .primary),
                                title: Text(
                                  categoryName,
                                  style: theme
                                      .textTheme.bodyLarge
                                      ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold,
                                    color: colorScheme
                                        .onSurface,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete,
                                      color: colorScheme
                                          .error),
                                  onPressed: () =>
                                      _deleteCategory(
                                          doc.id,
                                          categoryName),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
