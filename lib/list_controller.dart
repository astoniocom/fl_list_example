import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class ListController extends ValueNotifier<ListState> {
  final ExampleRecordQuery query;

  ListController({required this.query}) : super(ListState()) {
    loadRecords(query: query);
  }

  Future<List<ExampleRecord>> fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return loadedRecords;
  }

  Future<void> loadRecords({ExampleRecordQuery? query}) async {
    if (value.isLoading) return;

    value = value.copyWith(isLoading: true, error: "");

    try {
      final fetchResult = await fetchRecords(query);

      value = value.copyWith(isLoading: false, records: fetchResult);
    } catch (e) {
      value = value.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  repeatQuery() {
    return loadRecords(query: query);
  }
}
