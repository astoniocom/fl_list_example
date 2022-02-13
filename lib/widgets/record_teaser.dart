import 'dart:math';
import 'package:english_words/english_words.dart';
import 'package:fl_list_example/repository.dart';
import 'package:fl_list_example/models.dart';
import 'package:flutter/material.dart';

class RecordTeaser extends StatelessWidget {
  final ExampleRecord record;

  const RecordTeaser({required this.record, Key? key}) : super(key: key);

  _createRecord(BuildContext context) async {
    try {
      await MockRepository().createRecord(title: nouns[Random().nextInt(nouns.length)].toUpperCase(), weight: record.weight + 1);
    } on WeightDuplicate {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight duplicate')));
    } on RecordDoesNotExist {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RecordDoesNotExist exception')));
    }
  }

  _updateRecord(BuildContext context) async {
    int newWeight = record.weight + 1;
    try {
      while (true) {
        try {
          await MockRepository().updateRecord(record.id, weight: newWeight);
          break;
        } on WeightDuplicate {
          newWeight++;
        }
      }
    } on RecordDoesNotExist {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RecordDoesNotExist exception')));
    }
  }

  _deleteRecord(BuildContext context) async {
    try {
      await MockRepository().deleteRecord(record.id);
    } on RecordDoesNotExist {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RecordDoesNotExist exception')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(record.title),
      subtitle: Text("weight: ${record.weight}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => _createRecord(context), icon: const Icon(Icons.new_label)),
          IconButton(onPressed: () => _updateRecord(context), icon: const Icon(Icons.edit)),
          IconButton(onPressed: () => _deleteRecord(context), icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}
