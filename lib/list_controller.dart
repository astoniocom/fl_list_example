import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class ListController extends ValueNotifier<ListState> {
  ListController() : super(ListState()) {
    loadRecords();
  }

  Future<List<ExampleRecord>> _fetchRecords() async {
    final loadedRecords = await MockRepository().queryRecords();
    return loadedRecords;
  }

  Future<void> loadRecords() async {
    if (value.isLoading) return;

    value = value.copyWith(stage: ListStage.loading);

    try {
      final fetchResult = await _fetchRecords();

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
    return loadRecords();
  }
}
