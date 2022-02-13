import 'package:fl_list_example/models.dart';

enum LoadingFor { idle, replace, add }

class ListState {
  ListState({
    List<ExtendedExampleRecord>? records,
    this.loadingFor = LoadingFor.idle,
    this.hasLoadedAllRecords = false,
    this.error = '', // 1
  }) : recordsStore = records {
    if (isInitialized && !hasLoadedAllRecords && this.records.isEmpty) {
      throw Exception("Wrong list state: List is empty but has not loadedAllRecords marker");
    }
    if (hasLoadedAllRecords && hasError) {
      throw Exception("Wrong list state: Completly loaded list can not have error ($error)");
    }
  }

  final LoadingFor loadingFor;
  final bool hasLoadedAllRecords;

  final List<ExtendedExampleRecord>? recordsStore; // 3

  bool get isInitialized => recordsStore != null; // 3

  List<ExtendedExampleRecord> get records => recordsStore ?? List<ExtendedExampleRecord>.empty(); // 4

  final String error;

  bool get hasError => error.isNotEmpty; // 5

  bool get isLoading => loadingFor != LoadingFor.idle;

  bool canLoadMore() => !hasLoadedAllRecords && !isLoading && !hasError;

  // 7
  ListState copyWith({
    List<ExtendedExampleRecord>? records,
    LoadingFor? loadingFor,
    bool? hasLoadedAllRecords,
    String? error,
  }) {
    return ListState(
      records: records ?? recordsStore,
      loadingFor: loadingFor ?? this.loadingFor,
      hasLoadedAllRecords: hasLoadedAllRecords ?? this.hasLoadedAllRecords,
      error: error ?? this.error,
    );
  }
}
