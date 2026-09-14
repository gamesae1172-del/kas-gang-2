enum UserRole { admin, participant }

enum ResidentStatus { active, moved }

enum PaymentStatus { paid, unpaid }

enum TransactionType { income, expense }

class Resident {
  final String id;
  String name;
  String houseNumber;
  String phone;
  ResidentStatus status;

  Resident({
    required this.id,
    required this.name,
    required this.houseNumber,
    required this.phone,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'houseNumber': houseNumber,
    'phone': phone,
    'status': status.name,
  };

  factory Resident.fromJson(Map<String, dynamic> j) => Resident(
    id: j['id'],
    name: j['name'],
    houseNumber: j['houseNumber'],
    phone: j['phone'] ?? '',
    status: ResidentStatus.values.firstWhere(
      (x) => x.name == j['status'],
      orElse: () => ResidentStatus.active,
    ),
  );
}

class Payment {
  final String residentId;
  final int year;
  final int month;
  int amount;
  PaymentStatus status;
  DateTime? paidAt;

  Payment({
    required this.residentId,
    required this.year,
    required this.month,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  Map<String, dynamic> toJson() => {
    'residentId': residentId,
    'year': year,
    'month': month,
    'amount': amount,
    'status': status.name,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    residentId: j['residentId'],
    year: j['year'],
    month: j['month'],
    amount: j['amount'],
    status: PaymentStatus.values.firstWhere(
      (x) => x.name == j['status'],
      orElse: () => PaymentStatus.unpaid,
    ),
    paidAt: j['paidAt'] == null ? null : DateTime.parse(j['paidAt']),
  );
}

class CashTransaction {
  final String id;
  DateTime date;
  TransactionType type;
  String category;
  int amount;
  String description;

  CashTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.name,
    'category': category,
    'amount': amount,
    'description': description,
  };

  factory CashTransaction.fromJson(Map<String, dynamic> j) => CashTransaction(
    id: j['id'],
    date: DateTime.parse(j['date']),
    type: TransactionType.values.firstWhere(
      (x) => x.name == j['type'],
      orElse: () => TransactionType.income,
    ),
    category: j['category'],
    amount: j['amount'],
    description: j['description'] ?? '',
  );
}