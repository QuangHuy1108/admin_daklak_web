import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/finance_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceService _service = FinanceService();

  List<ExpenseModel> _expenses = [];
  double _totalGrossRevenue = 0;
  bool _isLoading = true;

  StreamSubscription? _expenseSub;
  StreamSubscription? _revenueSub;

  FinanceProvider() {
    _init();
  }

  void _init() {
    _expenseSub = _service.streamExpenses().listen((expenses) {
      _expenses = expenses;
      _isLoading = false;
      notifyListeners();
    });

    _revenueSub = _service.streamGrossRevenue().listen((revenue) {
      _totalGrossRevenue = revenue;
      notifyListeners();
    });
  }

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  double get totalGrossRevenue => _totalGrossRevenue;
  bool get isLoading => _isLoading;

  double get totalExpenses {
    return _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get netProfit {
    return _totalGrossRevenue - totalExpenses;
  }

  // Actions
  Future<void> addExpense(ExpenseModel expense) async {
    await _service.addExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _service.deleteExpense(id);
  }

  @override
  void dispose() {
    _expenseSub?.cancel();
    _revenueSub?.cancel();
    super.dispose();
  }
}
