import 'package:fl_list_example/models.dart';
import 'package:flutter/material.dart';

class RecordTeaser extends StatelessWidget {
  final ExampleRecord record;

  const RecordTeaser({required this.record, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(record.title),
      subtitle: Text("weight: ${record.weight}"),
    );
  }
}
