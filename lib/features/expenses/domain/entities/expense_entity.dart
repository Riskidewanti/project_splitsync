import 'package:equatable/equatable.dart';

import '../../data/models/expense_model.dart';

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.amount,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount,
    this.tags = const <String>[],
    this.note,
    this.receipt,
    this.ocrJobId,
  });

  final String id;
  final String groupId;
  final String paidBy;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final int? itemCount;
  final List<String> tags;
  final String? note;
  final String? receipt;
  final String? ocrJobId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExpenseEntity.fromModel(ExpenseModel model) {
    return ExpenseEntity(
      id: model.id,
      groupId: model.groupId,
      paidBy: model.paidBy,
      amount: model.amount,
      category: model.category,
      description: model.description,
      itemCount: model.itemCount,
      tags: model.tags,
      note: model.note,
      receipt: model.receipt,
      ocrJobId: model.ocrJobId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  ExpenseModel toModel() {
    return ExpenseModel(
      id: id,
      groupId: groupId,
      paidBy: paidBy,
      amount: amount,
      category: category,
      description: description,
      itemCount: itemCount,
      tags: tags,
      note: note,
      receipt: receipt,
      ocrJobId: ocrJobId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    groupId,
    paidBy,
    amount,
    category,
    description,
    itemCount,
    tags,
    note,
    receipt,
    ocrJobId,
    createdAt,
    updatedAt,
  ];
}
