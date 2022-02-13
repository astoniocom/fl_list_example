import 'package:fl_list_example/models.dart';

enum ListStage { idle, loading, error, complete }

class ListState {
  ListState({
    List<ExampleRecord>? records,
    this.stage = ListStage.idle,
  }) : recordsStore = records {
    if (isInitialized && stage != ListStage.complete && this.records.isEmpty) {
      throw Exception("List is empty but has stage marker other than `complete`");
    }
  }

  final List<ExampleRecord>? recordsStore;

  bool get isInitialized => recordsStore != null;
  
  final ListStage stage;

  List<ExampleRecord> get records => recordsStore ?? List<ExampleRecord>.empty();

  bool get hasError => stage == ListStage.error;

  bool get isLoading => stage == ListStage.loading;

  ListState copyWith({
    List<ExampleRecord>? records,
    ListStage? stage,
  }) {
    return ListState(
      records: records ?? recordsStore,
      stage: stage ?? this.stage,
    );
  }
}
