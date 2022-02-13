import 'dart:math';
import 'package:english_words/english_words.dart';
import 'package:fl_list_example/models.dart';

const kRecordsToGenerate = 100;

class MockRepository {
  final List<ExampleRecord> _store = List<ExampleRecord>.generate(
      kRecordsToGenerate,
      (i) => ExampleRecord(
            title: nouns[Random().nextInt(nouns.length)],
          ));

  static final MockRepository _instance = MockRepository._internal();
  factory MockRepository() => _instance;
  MockRepository._internal() : super();

  Future<List<ExampleRecord>> queryRecords() async {
    await Future.delayed(const Duration(seconds: 2));
    return _store;
  }
}
