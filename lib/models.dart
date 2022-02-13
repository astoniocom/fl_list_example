class ExampleRecord {
  final String title;
  final int weight;

  const ExampleRecord({
    required this.title,
    required this.weight,
  });
}

class ExampleRecordQuery {
  final String? contains;
  final int? weightGt;

  const ExampleRecordQuery({
    this.contains,
    this.weightGt,
  });

  bool fits(ExampleRecord obj) {
    if (contains != null && contains!.isNotEmpty && !obj.title.contains(contains!)) return false;
    if (weightGt != null && obj.weight <= weightGt!) return false;
    return true;
  }

  ExampleRecordQuery copyWith({int? weightGt}) {
    return ExampleRecordQuery(
      weightGt: weightGt ?? this.weightGt,
    );
  }

  int compareRecords(ExampleRecord record1, ExampleRecord record2) {
    return record1.weight.compareTo(record2.weight);
  }
}
