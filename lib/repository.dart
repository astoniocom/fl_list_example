import 'dart:async';
import 'dart:math';
import 'package:english_words/english_words.dart';
import 'package:fl_list_example/models.dart';
import 'package:collection/collection.dart';

const kRecordsToGenerate = 100;
const kBatchSize = 15;

class WeightDuplicate {}

class RecordDoesNotExist {}

class MockRepository {
  final List<ExampleRecord> _store = List<ExampleRecord>.generate(
      kRecordsToGenerate,
      (i) => ExampleRecord(
            id: i,
            weight: i * 10,
            title: nouns[Random().nextInt(nouns.length)],
          ))
    ..shuffle();

  final StreamController<RecordEvent> eventController = StreamController<RecordEvent>();
  late Stream<RecordEvent> rawEvents = eventController.stream.asBroadcastStream();

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

  Future<List<ExampleRecord>> getByIds(Iterable<ID> ids) async {
    return _store.where((record) => ids.contains(record.id)).toList();
  }

  Future<ID> createRecord({required String title, required int weight}) async {
    if (_store.where((element) => element.weight == weight).isNotEmpty) throw WeightDuplicate();
    final maxId = _store.isNotEmpty ? _store.map((e) => e.id).reduce(max) : 0;
    final newId = maxId + 1;
    _store.add(ExampleRecord(
      id: newId,
      title: title,
      weight: weight,
    ));
    eventController.add(RecordCreatedEvent(newId));
    return newId;
  }

  Future<void> updateRecord(ID id, {String? title, int? weight}) async {
    final ExampleRecord? record = _store.firstWhereOrNull((element) => element.id == id);
    if (record == null) throw RecordDoesNotExist();

    if (_store.where((element) => element != record && element.weight == weight).isNotEmpty) throw WeightDuplicate();
    final storeIndex = _store.indexOf(record);
    _store[storeIndex] = ExampleRecord(
      id: id,
      title: title ?? record.title,
      weight: weight ?? record.weight,
    );
    eventController.add(RecordUpdatedEvent(id));
  }

  Future<void> deleteRecord(ID id) async {
    final ExampleRecord? record = _store.firstWhereOrNull((element) => element.id == id);
    if (record == null) throw RecordDoesNotExist();
    _store.remove(record);
    eventController.add(RecordDeletedEvent(id));
  }
}
