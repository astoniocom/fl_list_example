import 'package:fl_list_example/models.dart';

class ListState {
  ListState({
    List<ExampleRecord>? records,
    this.isLoading = false,
    this.error = '', // 1
  }) : recordsStore = records; // 2

  final List<ExampleRecord>? recordsStore; // 3

  bool get isInitialized => recordsStore != null; // 3

  List<ExampleRecord> get records => recordsStore ?? List<ExampleRecord>.empty(); // 4

  final String error;

  bool get hasError => error.isNotEmpty; // 5

  final bool isLoading; // 6

  // 7
  ListState copyWith({
    List<ExampleRecord>? records,
    bool? isLoading,
    String? error,
  }) {
    return ListState(
      records: records ?? recordsStore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
