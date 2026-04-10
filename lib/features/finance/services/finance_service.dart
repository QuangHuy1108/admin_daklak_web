import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream current expenses
  Stream<List<ExpenseModel>> streamExpenses() {
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add a new expense record
  Future<void> addExpense(ExpenseModel expense) async {
    await _db.collection('expenses').add(expense.toMap());
  }

  // Delete an expense record (utility for the UI)
  Future<void> deleteExpense(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  // Stream completed orders to calculate gross revenue
  Stream<double> streamGrossRevenue() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'Completed')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dynamic rawAmount = data['totalAmount'] ?? 0;
        if (rawAmount is num) {
          total += rawAmount.toDouble();
        } else if (rawAmount is String) {
          total += double.tryParse(rawAmount) ?? 0;
        }
      }
      return total;
    });
  }
}
