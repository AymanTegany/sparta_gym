class Expense {
  final int? id;
  final String title;
  final String category; // إيجار, كهرباء, رواتب, معدات, مصروفات يومية
  final double amount;
  final String date;
  final String? notes;
  final String createdAt;

  Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount'],
      date: map['date'],
      notes: map['notes'],
      createdAt: map['createdAt'],
    );
  }
}
