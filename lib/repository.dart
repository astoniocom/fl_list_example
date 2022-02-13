import 'dart:math';
import 'package:english_words/english_words.dart';
import 'package:fl_list_example/models.dart';

const kRecordsToGenerate = 100;
const kBatchSize = 15;

class MockRepository {
  final List<ExampleRecord> _store = List<ExampleRecord>.generate(
      kRecordsToGenerate,
      (i) => ExampleRecord(
            weight: i * 10,
            title: nouns[Random().nextInt(nouns.length)],
          ))
    ..shuffle();

  static final MockRepository _instance = MockRepository._internal();
  factory MockRepository() => _instance;
  MockRepository._internal() : super();

  Future<List<ExampleRecord>> queryRecords(ExampleRecordQuery? query) async {
    await Future.delayed(const Duration(seconds: 2));

    final sortedList = List.of(_store);
    if (query != null) sortedList.sort(query.compareRecords);

    // if ((query?.weightGt ?? 0) > 400) throw "Test Exception";

    return sortedList.where((record) => query == null || query.fits(record)).take(kBatchSize).toList();
  }
}
