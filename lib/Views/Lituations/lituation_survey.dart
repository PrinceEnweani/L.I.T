import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Providers/ProfileProvider/view_profile_provider.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:popover/popover.dart';


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
            String me = widget.lituationVisit.userID;
            UserRate rating = _lit.rates
                    .firstWhere((element) => element.to == '-' && element.from == me, orElse: () => null);
            return ListView(children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rate this lituation",
                    style: TextStyle(color: Colors.white)),
                    if (rating == null)
                      Row(
                        children: [
                        TextButton(
                          child: Text(
                            "Rate",
                            style: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor),
                          ),
                          onPressed: () async {
                            double rate = await showDialog(
                              context: context,
                              builder: (context) => RatingPopover(),                          
                            );
                            if (rate != null && rate > 0 )
                              setRateUser('-', rate);
                          },
                        ),
                        ],
                      ),
                  if (rating != null)
                    SmoothStarRating(
                      rating: rating.rate * 1.0,
                      isReadOnly: true,
                      size: 18,
                      filledIconData: Icons.star,
                      halfFilledIconData: Icons.star_half,
                      defaultIconData: Icons.star_border,
                      starCount: 5,
                      allowHalfRating: true,
                      spacing: 2.0,
                      onRated: (value) {
                        print("rating value -> $value");
                      },
                    ),
                  ],
                )
              ),
              Divider(),
              Container(height:500, child:
              usersList(_lit)),
              ],);
          },
        ));
  }

  Widget vibeButton(String userID){    
    ViewProfileProvider provider = new ViewProfileProvider(userID);
    return StreamBuilder(
      stream: provider.vibingStream(),
      builder: (context , vibing){
        if(!vibing.hasData){
          return Container();
        }
        String val = 'vibe';
        Color btnColor = Theme.of(context).primaryColor;
        int status = 0; //0 vibe , 1 vibed , 2 pending
        if(List.from(vibing.data['vibing']).contains(widget.lituationVisit.userID)){
          val = 'vibed';
          btnColor = Colors.green;
          status = 1;
        }
        if(List.from(vibing.data['pendingVibing']).contains(widget.lituationVisit.userID)){
          val = 'cancel';
          btnColor = Colors.red;
          status = 2;
        }

        return Container( //lo
            height: 35,// in button
            margin: EdgeInsets.fromLTRB(5, 5, 10, 0),
            child: RaisedButton(
                color: btnColor,
                textColor: Theme.of(context).textSelectionColor,
                child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),                
                onPressed: () {
                  if(val == 'vibe')
                    provider.sendVibeRequest(widget.lituationVisit.userID);
                  else if(val == 'cancel')
                    provider.cancelVibeRequest(widget.lituationVisit.userID);
                }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
            )
        );

      },
    );
  }

  Widget usersList(Lituation _lit) {
    List<String> attendeesIDs = _lit.vibes;
    List<User> attendees = [];
    List<String> addedIDs = [];
    attendeesIDs.add(_lit.hostID);
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
                      _u.status?.status ?? "offline", _lit);
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

  setRateUser(String userID, double rate) async {
    // like user
    if (userID != '-')
      await lp.db.updateClout(userID, (rate * 10).round());
    await lp.db.setUserRateofLituation(widget.lituationVisit.lituationID,
        userID, widget.lituationVisit.userID, rate.round());
    _scaffoldKey.currentState.showSnackBar(sBar('Thanks for your rate!'));
  }

  Widget userItemWidget(String url, String userID, String username,
      String status, Lituation _lit) {
    String me = widget.lituationVisit.userID;
    bool online = getStatusAsBool(status);
    UserRate rating = _lit.rates
            .firstWhere((element) => element.to == userID && element.from == me, orElse: () => null);            
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
                if (rating == null)
                  Row(
                    children: [
                     TextButton(
                      child: Text(
                        "Rate",
                        style: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor),
                      ),
                      onPressed: () async {
                        double rate = await showDialog(
                          context: context,
                          builder: (context) => RatingPopover(),                          
                        );
                        if (rate != null && rate > 0 )
                          setRateUser(userID, rate);
                      },
                    ),
                    ],
                  ),
                if (rating != null)
                  SmoothStarRating(
                        rating: rating.rate * 1.0,
                        isReadOnly: true,
                        size: 18,
                        filledIconData: Icons.star,
                        halfFilledIconData: Icons.star_half,
                        defaultIconData: Icons.star_border,
                        starCount: 5,
                        allowHalfRating: true,
                        spacing: 2.0,
                        onRated: (value) {
                          print("rating value -> $value");
                        },
                      ),
                vibeButton(userID),
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


class RatingPopover extends StatelessWidget {
  RatingPopover({Key key}) : super(key: key);
  double rate = 3;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Container(height: 50,
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop(-1.0);
                },
                icon: Icon(Icons.close, color: Theme.of(context).secondaryHeaderColor,),))
            ),
            Container(
              height: 50,
              color: Colors.amber[200],
              child: SmoothStarRating(
                        rating: rate * 1.0,
                        isReadOnly: false,
                        size: 40,
                        filledIconData: Icons.star,
                        halfFilledIconData: Icons.star_half,
                        defaultIconData: Icons.star_border,
                        starCount: 5,
                        allowHalfRating: false,
                        spacing: 2.0,
                        onRated: (value) {
                          print("rating value -> $value");
                          rate = value;
                          // print("rating value dd -> ${value.truncate()}");
                        },
                      ),
            ),       
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                  ..pop(rate);
              },
              child: Container(
                height: 30,
                color: Colors.amber[100],
                child: const Center(child: Text('Submit')),
              ),
            ),     
          ],
        ),
      ));
  }
}
