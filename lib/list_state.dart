import 'package:fl_list_example/record_cubit.dart';

enum ListStage { idle, loading, error, complete }

class ListState {
  ListState({
    List<ExampleRecordCubit>? records,
    this.stage = ListStage.idle,
  }) : recordsStore = records {
    if (isInitialized && stage != ListStage.complete && this.records.isEmpty) {
      throw Exception("List is empty but has stage marker other than `complete`");
    }
  }

  final List<ExampleRecordCubit>? recordsStore;
  bool get isInitialized => recordsStore != null;

  final ListStage stage;

  List<ExampleRecordCubit> get records => recordsStore ?? List<ExampleRecordCubit>.empty();

  bool get hasError => stage == ListStage.error;

  bool get isLoading => stage == ListStage.loading;

  ListState copyWith({
    List<ExampleRecordCubit>? records,
    ListStage? stage,
  }) {
    return ListState(
      records: records ?? recordsStore,
      stage: stage ?? this.stage,
    );
  }
}
