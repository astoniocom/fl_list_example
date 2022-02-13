import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class ListController extends ValueNotifier<ListState> {

  ListController({required this.query}) : super(ListState()) {
    loadRecords(query);
  }

  final ExampleRecordQuery query;

  Future<List<ExampleRecord>> _fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return loadedRecords;
  }

  Future<void> loadRecords(ExampleRecordQuery? query) async {
    if (value.isLoading) return;

    value = value.copyWith(stage: ListStage.loading);

    try {
      final fetchResult = await _fetchRecords(query);

      value = value.copyWith(
        stage: ListStage.idle,
        records: fetchResult,
      );
    } catch (e) {
      value = value.copyWith(stage: ListStage.error);
      rethrow;
    }
  }

  repeatQuery() {
    return loadRecords(query);
  }
}
