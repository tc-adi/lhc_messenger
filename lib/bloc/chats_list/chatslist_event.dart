part of 'chatslist_bloc.dart';

abstract class ChatslistEvent extends Equatable {
  const ChatslistEvent();
}

class GetChatList extends ChatslistEvent {
  @override
  // TODO: implement props
  List<Object> get props => [];
}

class FetchChatsList extends ChatslistEvent {
  final Server server;

  const FetchChatsList({@required this.server}) : assert(server != null);

  @override
  List<Object> get props => [server];
}

abstract class ChatActionEvent extends ChatslistEvent {
  final Server server;
  final Chat chat;
  const ChatActionEvent({@required this.server, @required this.chat})
      : assert(server != null && chat != null);

  @override
  List<Object> get props => [server, chat];
}

class CloseChatMainPage extends ChatActionEvent {
  const CloseChatMainPage({@required Server server, @required Chat chat})
      : super(server: server, chat: chat);
}

class DeleteChatMainPage extends ChatActionEvent {
  const DeleteChatMainPage({@required Server server, @required Chat chat})
      : super(server: server, chat: chat);
}
