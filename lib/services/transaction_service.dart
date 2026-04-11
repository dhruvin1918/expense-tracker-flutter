import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  // DELETE TRANSACTION
  static Future<void> deleteTransaction({
    required String transactionId,
    required String walletId,
    required double amount,
    required String type, // income / expense
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
          'User must be authenticated to delete a transaction.');
    }

    final walletRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .doc(walletId);

    final transactionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(
            type == 'income' ? 'income' : 'expenses')
        .doc(transactionId);

    await FirebaseFirestore.instance
        .runTransaction((tx) async {
      final walletSnap = await tx.get(walletRef);
      final currentBalance =
          (walletSnap['balance'] ?? 0).toDouble();

      final newBalance = type == 'income'
          ? currentBalance - amount
          : currentBalance + amount;

      tx.update(walletRef, {'balance': newBalance});
      tx.delete(transactionRef);
    });
  }

  // UPDATE TRANSACTION
  static Future<void> updateTransaction({
    required String transactionId,
    required String walletId,
    required double oldAmount,
    required double newAmount,
    required String description,
    required String type, // income / expense
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
          'User must be authenticated to update a transaction.');
    }

    final walletRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .doc(walletId);

    final transactionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(
            type == 'income' ? 'income' : 'expenses')
        .doc(transactionId);

    await FirebaseFirestore.instance
        .runTransaction((tx) async {
      final walletSnap = await tx.get(walletRef);
      final currentBalance =
          (walletSnap['balance'] ?? 0).toDouble();

      double updatedBalance;
      if (type == 'income') {
        updatedBalance =
            currentBalance - oldAmount + newAmount;
      } else {
        updatedBalance =
            currentBalance + oldAmount - newAmount;
      }

      tx.update(walletRef, {'balance': updatedBalance});
      tx.update(transactionRef, {
        'amount': newAmount,
        'description': description,
      });
    });
  }
}
