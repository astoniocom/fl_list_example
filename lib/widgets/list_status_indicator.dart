import 'package:fl_list_example/list_state.dart';
import 'package:flutter/material.dart';

class ListStatusIndicator extends StatelessWidget {
  final ListState listState;
  final Function()? onRepeat;

  const ListStatusIndicator(this.listState, {this.onRepeat, Key? key}) : super(key: key);

  static bool hasStatus(ListState listState) => listState.hasError || listState.isLoading || (listState.isInitialized && listState.records.isEmpty);

  @override
  Widget build(BuildContext context) {
    // return const ListTile(title: Center(child: CircularProgressIndicator()));
    Widget? stateIndicator;
    if (listState.hasError) {
      stateIndicator = const Text("Loading Error", textAlign: TextAlign.center);
      if (onRepeat != null) {
        stateIndicator = Row(
          mainAxisSize: MainAxisSize.min,
          children: [stateIndicator, const SizedBox(width: 8), IconButton(onPressed: onRepeat, icon: const Icon(Icons.refresh))],
        );
      }
    } else if (listState.isLoading) {
      stateIndicator = const CircularProgressIndicator();
    } else if (listState.isInitialized && listState.records.isEmpty) {
      stateIndicator = const Text("No results", textAlign: TextAlign.center);
    }

    if (stateIndicator == null) return Container();

    return Container(alignment: Alignment.center, child: stateIndicator);
  }
}
