import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/login_form.dart';
import 'package:livehelp/pages/pages.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/widget/widget.dart';

import 'package:livehelp/globals.dart' as globals;

class ServersManage extends StatefulWidget {
  ServersManage({this.returnToList = false});
  // used to determine whether page was opened from MainPage
  final bool returnToList;
  @override
  ServersManageState createState() => new ServersManageState();
}

class ServersManageState extends State<ServersManage> with RouteAware {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;
  ServerBloc _serverBloc;
  var callbackAdded = false;

  var _tapPosition;

  @override
  void initState() {
    super.initState();
    _serverBloc = context.bloc<ServerBloc>()
      ..add(GetServerListFromDB(onlyLoggedIn: false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    globals.routeObserver.subscribe(this, ModalRoute.of(context));
  }

  // Called when the current route has been pushed.
  @override
  void didPush() {
    _serverBloc.add(GetServerListFromDB(onlyLoggedIn: false));
  }

  @override
  // Called when the top route has been popped off, and the current route shows up.
  void didPopNext() {
    _serverBloc.add(GetServerListFromDB(onlyLoggedIn: false));
  }

  @override
  void dispose() {
    globals.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = BlocConsumer<ServerBloc, ServerState>(
        listener: (context, state) {
          if (state is ServerInitial || state is ServerListLoading) {
            _serverBloc.add(GetServerListFromDB(onlyLoggedIn: false));
          }
          if (state is ServerLoggedOut) {
            _serverBloc.add(InitServers());
            _serverBloc.add(GetServerListFromDB(onlyLoggedIn: false));
          }
        },
        builder: _bodyBuilder);

    return scaffold;
  }

  Widget _bodyBuilder(BuildContext context, ServerState state) {
    if (state is ServerInitial || state is ServerListLoading) {
      return Scaffold(
          body: Center(
        child: CircularProgressIndicator(),
      ));
    }
    if (state is ServerListFromDBLoaded) {
      //If any server is logged in
      if (state.serverList.any((server) => server.isLoggedIn) && !widget.returnToList && callbackAdded == false) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
                FadeRoute(
                  builder: (BuildContext context) => MainPage(),
                  settings: RouteSettings(
                    name: AppRoutes.home,
                  ),
                ),
                    (Route<dynamic> route) => false);
          });
          callbackAdded = true;
      }
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        key: _scaffoldKey,
        appBar: new AppBar(
          title: Text("Manage Servers"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[],
        ),
        body: ListView.builder(
            itemCount: state.serverList.length,
            itemBuilder: (context, index) {
              Server server = state.serverList[index];
              return new GestureDetector(
                child: ServerItemWidget(
                    server: server,
                    menuBuilder: _itemMenuBuilder(),
                    onMenuSelected: (selectedOption) {}),
                onTap: () {
                  if (server.isLoggedIn) {
                    if (widget.returnToList) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                          LHCRouter.Router.generateRoute(RouteSettings(
                              name: LHCRouter.AppRoutes.home,
                              arguments: LHCRouter.RouteArguments())));
                    }
                  } else {
                    _showAlertMsg("Not Logged In",
                        "You are logged out of this server.\n\nLongPress Server for options");
                  }
                },
                onLongPress: () {
                  _showCustomMenu(server);
                },
                onTapDown: _storePosition,
              );
            }),
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.add),
          onPressed: () {
            _addServer();
          },
        ),
      );
    }
    return ErrorReloadButton(
        onButtonPress: () {
          _serverBloc.add(InitServers());
        },
        actionText: "Reload");
  }

  void _addServer({Server svr}) {
    //Navigator.of(context).pop();
    Navigator.of(context).push(LHCRouter.FadeRoute(
      builder: (BuildContext context) {
        return LoginForm(
          server: svr,
        );
      },
      settings: new RouteSettings(
        name: LHCRouter.AppRoutes.login,
      ),
    ));
  }

  void _showCustomMenu(Server sv) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();

    showMenu(
            context: context,
            items: _itemMenuBuilder(),
            position: RelativeRect.fromRect(_tapPosition & Size(40, 40),
                Offset.zero & overlay.semanticBounds.size))
        // This is how you handle user selection
        .then<void>((ServerItemMenuOption option) {
      //  if (option == null) return;
      switch (option) {
        case ServerItemMenuOption.MODIFY:
          _addServer(svr: sv);
          break;
        case ServerItemMenuOption.REMOVE:
          _showAlert(context, sv);
          break;
        default:
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  List<PopupMenuEntry<ServerItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ServerItemMenuOption>>[
      const PopupMenuItem<ServerItemMenuOption>(
        value: ServerItemMenuOption.MODIFY,
        child: const Text('Modify / Login'),
      ),
      const PopupMenuItem<ServerItemMenuOption>(
        value: ServerItemMenuOption.REMOVE,
        child: const Text('Remove'),
      ),
    ];
  }

  void _showAlert(BuildContext context, Server srvr) {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "Do you want to remove the server?",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Yes"),
            onPressed: () async {
              String fcmToken = context.bloc<FcmTokenBloc>().token;
              context.bloc<ServerBloc>().add(LogoutServer(
                  server: srvr, fcmToken: fcmToken, deleteServer: true));
              Navigator.of(context).pop();
            }),
        MaterialButton(
            child: new Text("No"),
            onPressed: () async {
              Navigator.of(context).pop();
            }),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void _showAlertMsg(String title, String msg) {
    SimpleDialog dialog = new SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(16.00, 8.00, 16.00, 8.00),
      contentPadding: const EdgeInsets.fromLTRB(8.00, 0.00, 16.00, 8.00),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.00),
          child: Text(
            msg,
            style: TextStyle(fontSize: 14.0),
          ),
        ),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }
}
