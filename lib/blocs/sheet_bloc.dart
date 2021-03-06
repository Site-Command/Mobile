import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:twake/repositories/sheet_repository.dart';

part '../events/sheet_event.dart';
part '../states/sheet_state.dart';

class SheetBloc extends Bloc<SheetEvent, SheetState> {
  final SheetRepository repository;
  SheetBloc(this.repository) : super(SheetInitial(flow: repository.flow));

  @override
  Stream<SheetState> mapEventToState(
    SheetEvent event,
  ) async* {
    if (event is InitSheet) {
      yield SheetInitial(
        flow: repository.flow,
      );
    } else if (event is OpenSheet) {
      yield SheetShouldOpen();
      // await repository.clean();
      // yield ProfileEmpty();
    } else if (event is CloseSheet) {
      yield SheetShouldClose();
    } else if (event is SetClosed) {
      yield SheetClosed();
    } else if (event is SetOpened) {
      yield SheetOpened();
    } else if (event is ClearSheet) {
      yield SheetShouldClear();
    } else if (event is ResetSheet) {
      yield SheetShouldReset();
    } else if (event is ProcessSheet) {
      yield SheetProcessing();
    }
  }
}
