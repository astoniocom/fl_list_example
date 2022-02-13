import 'dart:async';

import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class ExampleRecordCubit extends ValueNotifier {
  late StreamSubscription _changesSubscription;

  ExampleRecordCubit(ExampleRecord initState) : super(initState) {
    _changesSubscription = MockRepository()
        .rawEvents
        .where((event) => event is RecordUpdatedEvent && event.id == value.id)
        .asyncMap((event) => MockRepository().getByIds([event.id]).then((value) => value.first))
        .listen((event) => value = event);
  }

  close() => _changesSubscription.cancel();

  ID get id => value.id;
  int get weight => value.weight;
  String get title => value.title;
}
