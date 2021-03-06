import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/add_channel_bloc.dart';
import 'package:twake/blocs/profile_bloc.dart';
import 'package:twake/blocs/user_bloc.dart';
import 'package:twake/repositories/add_channel_repository.dart';
import 'package:twake/widgets/sheets/channel_info_form.dart';
import 'package:twake/widgets/sheets/channel_type_form.dart';
import 'package:twake/widgets/sheets/channel_groups_list.dart';
import 'package:twake/widgets/sheets/channel_participants_list.dart';

class AddChannelFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final widgets = [
      ChannelInfoForm(),
      ChannelTypeForm(),
      ChannelGroupsList(),
      ChannelParticipantsList(),
    ];

    return BlocProvider<UserBloc>(
      create: (_) => UserBloc(ProfileBloc.userId),
      child: BlocBuilder<AddChannelBloc, AddChannelState>(
        buildWhen: (previous, current) =>
            current is StageUpdated || current is FlowTypeSet,
        builder: (context, state) {
          if (state is FlowTypeSet) {
            if (state.isDirect) {
              return ChannelParticipantsList(
                isDirect: true,
              );
            }
          }
          var i = 0;
          if (state is StageUpdated) {
            switch (state.stage) {
              case FlowStage.info:
                i = 0;
                break;
              case FlowStage.type:
                i = 1;
                break;
              case FlowStage.groups:
                i = 2;
                break;
              case FlowStage.participants:
                i = 3;
                break;
            }
          }
          return IndexedStack(
            index: i,
            children: widgets,
          );
        },
      ),
    );
  }
}
