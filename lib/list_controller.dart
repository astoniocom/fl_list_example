import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class ListController extends ValueNotifier<ListState> {
  ListController() : super(ListState()) {
    loadRecords();
  }

  Future<List<ExampleRecord>> fetchRecords() async {
    final loadedRecords = await MockRepository().queryRecords();
    return loadedRecords;
  }

  Future<void> loadRecords() async {
    if (value.isLoading) return;

    value = value.copyWith(isLoading: true, error: "");

    try {
      final fetchResult = await fetchRecords();

      value = value.copyWith(isLoading: false, records: fetchResult);
    } catch (e) {
      value = value.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  repeatQuery() {
    return loadRecords();
  }
}
