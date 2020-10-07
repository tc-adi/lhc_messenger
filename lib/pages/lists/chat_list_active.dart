import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/widget/chat_item_widget.dart';
import 'package:livehelp/pages/chat/chat_page.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class ActiveListWidget extends StatefulWidget {
  final List<Server> listOfServers;
  final VoidCallback refreshList;
  final Function(Server, Chat) callbackCloseChat;
  final Function(Server, Chat) callBackDeleteChat;

  ActiveListWidget(
      {Key key,
      this.listOfServers,
      this.refreshList,
      @required this.callbackCloseChat,
      @required this.callBackDeleteChat})
      : super(key: key);

  @override
  _ActiveListWidgetState createState() => new _ActiveListWidgetState();
}

class _ActiveListWidgetState extends State<ActiveListWidget> {
  ServerRepository _serverRepository;

  @override
  void initState() {
    super.initState();
    _serverRepository = context.repository<ServerRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatslistBloc, ChatListState>(builder: (context, state) {
      if (state is ChatslistInitial) {
        return Center(child: CircularProgressIndicator());
      }

      if (state is ChatListLoaded) {
        return ListView.builder(
            itemCount: state.activeChatList.length,
            itemBuilder: (BuildContext context, int index) {
              Chat chat = state.activeChatList[index];
              Server server = widget.listOfServers.firstWhere(
                  (srvr) => srvr.id == chat.serverid,
                  orElse: () => null);

              return server == null
                  ? Text("No server found")
                  : new GestureDetector(
                      child: new ChatItemWidget(
                        server: server,
                        chat: chat,
                        menuBuilder: _itemMenuBuilder(),
                        onMenuSelected: (selectedOption) {
                          onItemSelected(context, server, chat, selectedOption);
                        },
                      ),
                      onTap: () {
                        var route = new FadeRoute(
                          settings: new RouteSettings(name: AppRoutes.chatPage),
                          builder: (BuildContext context) => ChatPage(
                            server: server,
                            chat: chat,
                            isNewChat: false,
                            refreshList: widget.refreshList,
                          ),
                        );
                        Navigator.of(context).push(route);
                      },
                    );
            });
      }
      if (state is ChatListLoadError) {
        return Text("An error occurred: ${state.message}");
      }
      return ListView.builder(
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) {
            return Text("No list available");
          });
    });
  }

  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ChatItemMenuOption>>[
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.CLOSE,
        child: const Text('Close'),
      ),
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.REJECT,
        child: const Text('Delete'),
      ),
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.TRANSFER,
        child: const Text('Transfer'),
      ),
    ];
  }

  void onItemSelected(
      BuildContext ctx, Server srv, Chat chat, ChatItemMenuOption result) {
    switch (result) {
      case ChatItemMenuOption.CLOSE:
        widget.callbackCloseChat(srv, chat);
        break;
      case ChatItemMenuOption.REJECT:
        widget.callBackDeleteChat(srv, chat);
        break;
      case ChatItemMenuOption.TRANSFER:
        // widget.loadingState(true);
        _showOperatorList(ctx, srv, chat);
        //_getOperatorList(ctx,srv,chat);
        break;
      default:
        break;
    }
  }

  Future<List<dynamic>> _getOperatorList(
      BuildContext context, Server srvr, Chat chat) async {
    return await _serverRepository.getOperatorsList(srvr);
  }

  Future<Null> _onRefresh() {
    Completer<Null> completer = new Completer<Null>();
    Timer timer = new Timer(new Duration(seconds: 3), () {
      completer.complete();
    });
    return completer.future;
  }

  void _showOperatorList(BuildContext context, Server srvr, Chat chat) {
    var futureBuilder = new FutureBuilder(
      future: _getOperatorList(context, srvr, chat),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return new Text('loading...');
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else
              return createListView(context, snapshot, srvr, chat);
        }
      },
    );

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Container(
              child: new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Text(
                  "Select online operator",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                new Divider(),
                Expanded(
                  child: futureBuilder,
                )
              ],
            ),
          ));
        });
  }

  Future<bool> _transferToUser(Server srvr, Chat chat, int userid) async {
    return _serverRepository.transferChatUser(srvr, chat, userid);
  }

  Widget createListView(
      BuildContext context, AsyncSnapshot snapshot, Server srvr, Chat chat) {
    List<dynamic> listOP = snapshot.data;

    return listOP != null
        ? new ListView.builder(
            reverse: false,
            padding: new EdgeInsets.all(6.0),
            itemCount: listOP.length,
            itemBuilder: (_, int index) {
              Map operator = listOP[index];
              return new ListTile(
                title: new Text(
                    'Name: ${operator["name"]} ${operator["surname"]}'),
                subtitle: new Text('Title: ${operator["job_title"]}'),
                onTap: () async {
                  await _transferToUser(srvr, chat, int.parse(operator['id']));
                  Navigator.of(context).pop();
                },
              );
            },
          )
        : new Text('No online operator found!');
  }
}
