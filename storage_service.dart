import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _residentsKey = 'residents';
  static const _paymentsKey = 'payments';
  static const _transactionsKey = 'transactions';

  Future<List<Resident>> loadResidents() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_residentsKey) ?? [];
    return raw.map((x) => Resident.fromJson(jsonDecode(x))).toList();
  }

  Future<List<Payment>> loadPayments() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_paymentsKey) ?? [];
    return raw.map((x) => Payment.fromJson(jsonDecode(x))).toList();
  }

  Future<List<CashTransaction>> loadTransactions() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_transactionsKey) ?? [];
    return raw.map((x) => CashTransaction.fromJson(jsonDecode(x))).toList();
  }

  Future<void> saveResidents(List<Resident> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _residentsKey,
      data.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<void> savePayments(List<Payment> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _paymentsKey,
      data.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<void> saveTransactions(List<CashTransaction> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _transactionsKey,
      data.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<String> exportJson({
    required List<Resident> residents,
    required List<Payment> payments,
    required List<CashTransaction> transactions,
  }) async {
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'residents': residents.map((x) => x.toJson()).toList(),
      'payments': payments.map((x) => x.toJson()).toList(),
      'transactions': transactions.map((x) => x.toJson()).toList(),
    });
  }

  Future<void> restoreJson(String raw) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final residents = (j['residents'] as List)
        .map((x) => Resident.fromJson(Map<String, dynamic>.from(x))).toList();
    final payments = (j['payments'] as List)
        .map((x) => Payment.fromJson(Map<String, dynamic>.from(x))).toList();
    final transactions = (j['transactions'] as List)
        .map((x) => CashTransaction.fromJson(Map<String, dynamic>.from(x))).toList();

    await saveResidents(residents);
    await savePayments(payments);
    await saveTransactions(transactions);
  }
}