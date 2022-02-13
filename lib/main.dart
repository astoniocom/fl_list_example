import 'package:fl_list_example/list_controller.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/widgets/list_status_indicator.dart';
import 'package:fl_list_example/widgets/record_teaser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => ListController(query: const ExampleRecordQuery(contains: "ea")),
        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final listController = context.watch<ListController>();
    final listState = listController.value;
    final itemCount = listState.records.length + (ListStatusIndicator.hasStatus(listState) ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text("List Demo")),
      body: ListView.builder(
        itemBuilder: (context, index) {
          if (index == listState.records.length && ListStatusIndicator.hasStatus(listState)) {
            return ListStatusIndicator(listState, onRepeat: listController.repeatQuery);
          }

          final record = listState.records[index];
          return RecordTeaser(record: record);
        },
        itemCount: itemCount,
      ),
    );
  }
}
