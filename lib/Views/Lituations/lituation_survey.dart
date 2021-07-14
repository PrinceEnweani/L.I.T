import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Styles/text_styles.dart';

class LituationSurveyPage extends StatefulWidget {
  final LituationVisit lituationVisit;
  LituationSurveyPage(this.lituationVisit);

  @override
  _LituationSurveyPageState createState() => new _LituationSurveyPageState();
}

class _LituationSurveyPageState extends State<LituationSurveyPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LituationProvider lp;
  Color likeColor = Colors.amber;
  Color dislikeColor = Colors.red;

  @override
  void initState() {
    lp = LituationProvider(
        widget.lituationVisit.lituationID, widget.lituationVisit.userID);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: appbar(context),
        body: StreamBuilder(
          stream: lp.lituationStream(),
          builder: (context, l) {
            if (!l.hasData) {
              return Container();
            }
            Lituation _lit = Lituation.fromJson(l.data.data());
            return usersList(_lit);
          },
        ));
  }

  Widget usersList(Lituation _lit) {
    List<String> attendeesIDs = _lit.vibes;
    List<User> attendees = [];
    List<String> addedIDs = [];
    return StreamBuilder(
      stream: lp.usersStream(),
      builder: (context, u) {
        if (!u.hasData) {
          return CircularProgressIndicator();
        }

        for (var user in u.data.docs) {
          User _u = User.fromJson(user.data());
          if (attendeesIDs.contains(_u.userID) &&
              _u.userID != widget.lituationVisit.userID) {
            if (!addedIDs.contains(_u.userID)) {
              attendees.add(_u);
              addedIDs.add(_u.userID);
            }
          }
        }
        if (attendees.length > 0) {
          return Container(
            padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: attendees.length,
                itemBuilder: (context, idx) {
                  User _u = attendees[idx];
                  return userItemWidget(_u.profileURL, _u.userID, _u.username,
                      _u.status?.status ?? "offline");
                }),
          );
        } else {
          return Container();
        }
      },
    );
  }

  void _viewProfile(String id, String username) {
    UserVisit v = UserVisit();
    v.visitorID = widget.lituationVisit.userID;
    v.visitedID = id;
    v.visitNote = username;
    print(v.visitNote);
    Navigator.pushNamed(context, VisitProfilePageRoute, arguments: v);
  }

  SnackBar sBar(String text) {
    return SnackBar(
        backgroundColor: Theme.of(context).primaryColor,
        content: Text(
          text,
          style: TextStyle(color: Theme.of(context).textSelectionColor),
        ));
  }

  Widget userItemWidget(
      String url, String userID, String username, String status) {
    bool online = getStatusAsBool(status);
    return Container(
        child: Stack(
      children: [
        Row(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              child: CachedNetworkImage(
                height: 45,
                width: 45,
                imageUrl: url,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: getStatusRingColor(online)),
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(
                      Theme.of(context).splashColor),
                ),
                errorWidget: (context, url, error) => nullProfileUrl(context),
              ),
            ),
            Container(
                margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: new Text(
                  username,
                  style: infoValue(Theme.of(context).textSelectionColor),
                  textAlign: TextAlign.center,
                  textScaleFactor: 0.9,
                )),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    // like user
                    lp.db.updateClout(userID, 10);
                    _scaffoldKey.currentState
                        .showSnackBar(sBar('Thanks for your rate!'));
                  },
                  icon: Icon(
                    Icons.local_fire_department,
                    color: likeColor,
                    size: 25,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    //dislike user
                    lp.db.updateClout(userID, -10);
                    _scaffoldKey.currentState
                        .showSnackBar(sBar('Thanks for your rate!'));
                  },
                  icon: Icon(
                    Icons.fire_extinguisher,
                    color: dislikeColor,
                    size: 25,
                  ),
                ),
                TextButton(
                  child: Text(
                    "Detail",
                    style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor),
                  ),
                  onPressed: () {
                    //Rate the user
                    if (userID != widget.lituationVisit.userID) {
                      _viewProfile(userID, widget.lituationVisit.userID);
                    }
                  },
                )
              ],
            )),
          ],
        ),
      ],
    ));
  }

  Widget appbar(BuildContext ctx) {
    return AppBar(
      leading: Container(
        padding: EdgeInsets.all(10),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textSelectionColor,
            size: 25,
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      title: Container(
          padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
          child: Text(
            "Rating users",
            style: TextStyle(color: Theme.of(context).textSelectionColor),
          )),
    );
  }
}
