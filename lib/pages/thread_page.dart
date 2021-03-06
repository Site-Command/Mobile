import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/base_channel_bloc.dart';
import 'package:twake/blocs/draft_bloc.dart';
import 'package:twake/blocs/message_edit_bloc.dart';
import 'package:twake/blocs/threads_bloc.dart';
import 'package:twake/config/dimensions_config.dart' show Dim;
import 'package:twake/models/direct.dart';
import 'package:twake/repositories/draft_repository.dart';
import 'package:twake/widgets/common/stacked_image_avatars.dart';
import 'package:twake/widgets/common/text_avatar.dart';
import 'package:twake/widgets/message/message_edit_field.dart';
import 'package:twake/widgets/thread/thread_messages_list.dart';

class ThreadPage<T extends BaseChannelBloc> extends StatelessWidget {
  final bool autofocus;

  const ThreadPage({this.autofocus: false});

  @override
  Widget build(BuildContext context) {
    String threadId;
    String draft;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        shadowColor: Colors.grey[300],
        toolbarHeight: Dim.heightPercent((kToolbarHeight * 0.15).round()),
        leading: BlocConsumer<DraftBloc, DraftState>(
            listener: (context, state) {
              if (state is DraftSaved || state is DraftError)
                Navigator.of(context).pop();
            },
            buildWhen: (_, current) =>
                current is DraftUpdated || current is DraftReset,
            builder: (context, state) {
              if (state is DraftUpdated) {
                threadId = state.id;
                draft = state.draft;
              } else if (state is DraftReset) {
                draft = '';
              }

              return BackButton(
                onPressed: () {
                  if (draft != null) {
                    if (draft.isNotEmpty) {
                      context.read<DraftBloc>().add(SaveDraft(
                            id: threadId,
                            type: DraftType.thread,
                            draft: draft,
                          ));
                    } else {
                      context.read<DraftBloc>().add(
                          ResetDraft(id: threadId, type: DraftType.thread));
                      Navigator.of(context).pop();
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              );
            }),
        title:
            BlocBuilder<ThreadsBloc<T>, MessagesState>(builder: (ctx, state) {
          return Row(
            children: [
              state.parentChannel is Direct
                  ? StackedUserAvatars((state.parentChannel as Direct).members)
                  : TextAvatar(
                      state.parentChannel.icon,
                      fontSize: Dim.tm4(),
                    ),
              SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Threaded replies',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff444444),
                    ),
                  ),
                  SizedBox(height: 1.0),
                  Text(
                    state.parentChannel.name,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff92929C),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
      body: SafeArea(
        child: BlocListener<ThreadsBloc<T>, MessagesState>(
          listener: (ctx, state) {
            state = state;
            if (state is ErrorSendingMessage) {
              FocusManager.instance.primaryFocus.unfocus();
              Scaffold.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Error sending message, no connection'),
                ),
              );
            }
          },
          child: Container(
            constraints: BoxConstraints(
              maxHeight: Dim.heightPercent(88),
              minHeight: Dim.heightPercent(78),
            ),
            child: BlocProvider<MessageEditBloc>(
              create: (ctx) => MessageEditBloc(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThreadMessagesList<T>(),
                  BlocBuilder<DraftBloc, DraftState>(
                      buildWhen: (_, current) =>
                          current is DraftLoaded || current is DraftReset,
                      builder: (context, state) {
                        if (state is DraftLoaded &&
                            state.type != DraftType.channel &&
                            state.type != DraftType.direct) {
                          draft = state.draft;
                        } else if (state is DraftReset) {
                          draft = '';
                        }
                        final threadState =
                            BlocProvider.of<ThreadsBloc<T>>(context).state;
                        threadId = threadState.threadMessage.id;

                        return BlocBuilder<MessageEditBloc, MessageEditState>(
                          builder: (ctx, state) => MessageEditField(
                            key: UniqueKey(),
                            initialText: state is MessageEditing
                                ? state.originalStr
                                : draft ?? '',
                            onMessageSend: state is MessageEditing
                                ? state.onMessageEditComplete
                                : (content) {
                                    BlocProvider.of<ThreadsBloc<T>>(context)
                                        .add(
                                      SendMessage(
                                        content: content,
                                        channelId: threadState.parentChannel.id,
                                        threadId: threadState.threadMessage.id,
                                      ),
                                    );
                                    context.read<DraftBloc>().add(ResetDraft(
                                        id: threadState.threadMessage.id,
                                        type: DraftType.thread));
                                  },
                            onTextUpdated: state is MessageEditing
                                ? (text) {}
                                : (text) {
                                    context.read<DraftBloc>().add(UpdateDraft(
                                          id: threadId,
                                          type: DraftType.thread,
                                          draft: text,
                                        ));
                                  },
                            autofocus: autofocus || state is MessageEditing,
                          ),
                        );
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
