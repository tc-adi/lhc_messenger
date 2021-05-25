part of 'chatslist_bloc.dart';

enum ChatListName { active, pending, transfer, twilio, closed, operators }

abstract class ChatListState extends Equatable {
  ChatListState();

  @override
  List<Object> get props => [];
}

class ChatslistInitial extends ChatListState {}

class ChatListLoadError extends ChatListState {
  final String message;

  ChatListLoadError({this.message});

  @override
  List<Object> get props => [message];
}

class ChatListLoaded extends ChatListState {
  final List<Chat> activeChatList;
  final List<Chat> pendingChatList;
  final List<Chat> transferChatList;
  final List<Chat> twilioChatList;
  final List<Chat> closedChatList;
  final List<User> operatorsChatList;
  final bool isLoading;

  ChatListLoaded(
      {this.activeChatList = const [],
      this.pendingChatList = const [],
      this.transferChatList = const [],
      this.twilioChatList = const [],
      this.closedChatList = const [],
      this.operatorsChatList = const [],
      this.isLoading = false});

  ChatListLoaded copyWith(
      {List<Chat> activeChatList,
      List<Chat> pendingChatList,
      List<Chat> transferChatList,
      List<Chat> twilioChatList,
      List<Chat> closedChatList,
      List<User> operatorsChatList,
      bool isLoading = false}) {
    return ChatListLoaded(
        activeChatList: activeChatList ?? this.activeChatList,
        pendingChatList: pendingChatList ?? this.pendingChatList,
        transferChatList: transferChatList ?? this.transferChatList,
        twilioChatList: twilioChatList ?? this.twilioChatList,
        closedChatList: closedChatList ?? this.closedChatList,
        operatorsChatList: operatorsChatList ?? this.operatorsChatList,
        isLoading: isLoading ?? this.isLoading);
  }

  @override
  List<Object> get props => [
        activeChatList,
        pendingChatList,
        transferChatList,
        twilioChatList,
        closedChatList,
        operatorsChatList,
        isLoading
      ];
}
