import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/SearchProvider/search_provider.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:lit_beta/Styles/theme_resolver.dart';
import 'package:lit_beta/Utils/Common.dart';
import 'package:location/location.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

class FeedPage extends StatefulWidget {
  final String userID;
  FeedPage({Key key, this.userID}) : super(key: key);

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<FeedPage> {
  SearchProvider sp;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  int _tabIndex = 0;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    sp = new SearchProvider(widget.userID);
    configurePushNotification();
    requestMapPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor, body: feedWidget());
  }

  void requestMapPermission() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

  void gotoSurvey(String id) {
    LituationVisit lv = LituationVisit();
    lv.userID = widget.userID;
    lv.lituationID = id;
    Navigator.pushReplacementNamed(context, LituationSurveyRoute,
        arguments: lv);
  }

  configurePushNotification() {
    _firebaseMessaging.requestPermission();

    _firebaseMessaging.getToken().then((token) {
      sp.db.updateUserPushToken(widget.userID, token);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
      print('onMessageOpenedApp: from:${event.from} ${event.data}');
      if (event.data["event"] == "lituation_survey") {
        String litID = event.data["litID"];
        gotoSurvey(litID);
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print('onMessage: from:${event.from} ${event.data}');
      if (event.data["event"] == "lituation_survey") {
        String litID = event.data["litID"];
        gotoSurvey(litID);
      }
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Widget feedWidget() {
    return Stack(
      children: [
        feedIndexedStackProvider(),
        Align(
          alignment: Alignment.topCenter,
          child: feedTabs(),
        )
      ],
    );
  }

  Widget feedIndexedStackProvider() {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              lituationsTab(1), // Recommend Lituations
              lituationsTab(1) // Trending Lituations
            ],
          ),
        )
      ],
    );
  }

  Widget lituationsTab(int type) {
    return Container(
        margin: EdgeInsets.only(top: 85),
        child: FutureBuilder(
          builder: (context, projectSnap) {
            if (projectSnap.connectionState != ConnectionState.done ||
                projectSnap.hasData == false) {
              return Center(child: CircularProgressIndicator());
            }
            List<Lituation> data = projectSnap.data;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, idx) {
                return lituationCard(data[idx], context, widget.userID);
              },
            );
          },
          future: type == 1
              ? sp.getRecommendLituations()
              : sp.getTrendingLituations(),
        ));
  }

  Widget feedTabs() {
    return Container(
      width: 250,
      margin: EdgeInsets.only(top: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: tappableTab('Recommended', 0),
          ),
          Expanded(
            child: tappableTab('Trending', 1),
          ),
        ],
      ),
    );
  }

  Widget tappableTab(String title, int idx) {
    Color c = Theme.of(context).buttonColor;
    Widget indicator = Container();
    var scale = 0.8;
    if (idx == _tabIndex) {
      scale = 1.1;
      title = title + '\n' + 'Lituations';
      indicator = selectedIndicator(Theme.of(context).textSelectionColor);
      c = Theme.of(context).textSelectionColor;
    }
    return Container(
        height: 50,
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 9,
                child: Text(
                  title,
                  style: TextStyle(color: c),
                  textAlign: TextAlign.center,
                  textScaleFactor: scale,
                ),
              ),
              indicator
            ],
          ),
          onTap: () {
            setState(() {
              _tabIndex = idx;
            });
          },
        ));
  }
}
