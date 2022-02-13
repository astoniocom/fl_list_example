typedef ID = int;

class ExampleRecord {
  final ID id;
  final String title;
  final int weight;

  const ExampleRecord({
    required this.id,
    required this.title,
    required this.weight,
  });
}

class ExampleRecordQuery {
  final String? contains;
  final int? weightGt;
  final int? weightLte;

  const ExampleRecordQuery({
    this.contains,
    this.weightGt,
    this.weightLte,
  });

  bool fits(ExampleRecord obj) {
    if (contains != null && contains!.isNotEmpty && !obj.title.contains(contains!)) return false;
    if (weightGt != null && obj.weight <= weightGt!) return false;
    if (weightLte != null && obj.weight > weightLte!) return false;
    return true;
  }

  ExampleRecordQuery copyWith({int? weightGt, int? weightLte}) {
    return ExampleRecordQuery(
      weightGt: weightGt ?? this.weightGt,
      weightLte: weightLte ?? this.weightLte,
    );
  }

  int compareRecords(ExampleRecord record1, ExampleRecord record2) {
    return record1.weight.compareTo(record2.weight);
  }
}

abstract class RecordEvent {
  final ID id;

  RecordEvent(this.id);
}

class RecordCreatedEvent extends RecordEvent {
  RecordCreatedEvent(ID id) : super(id);
}

class RecordUpdatedEvent extends RecordEvent {
  RecordUpdatedEvent(ID id) : super(id);
}

class RecordDeletedEvent extends RecordEvent {
  RecordDeletedEvent(ID id) : super(id);
}
