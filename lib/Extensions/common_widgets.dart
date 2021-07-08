import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:lit_beta/Utils/Common.dart';

import 'common_functions.dart';

Widget selectedIndicator(Color c) {
  return Container(
    height: 0.7,
    width: 75,
    color: c,
  );
}
Widget divider(Color c) {
  return Container(
    height: 25,
    width: 0.7,
    color: c,
  );
}
Widget horizontalDivider(Color c , double w) {
  return Opacity(opacity: 0.3,
  child: Container(
      margin: EdgeInsets.only(left: 10 , right: 10),
  height: 0.7,
  width: w,
  color: c,
  ),
  );
}
  Widget topNav(Widget leading , Widget title , List<Widget> actions, Color c){
    return AppBar(
      backgroundColor: c,
      centerTitle: true,
      leading: leading,
      title: title,
      actions: actions,
    );
  }

Widget nullUrl(){
  return Container(
    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.4,
          child: Image.asset('assets/images/litlogo.png'),
        )
      ],
    ),
  );
}

Widget minimizeableList(Widget listWidget , bool minimize){
  if(minimize){
    return Container();
  }else{
    return listWidget;
  }
}
Widget nullProfileUrl(BuildContext context){
  return Container(
    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    width: 125.0,
    height: 125.0,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.lightGreen),
      borderRadius: BorderRadius.circular(75),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.8,
          child: Image.asset('assets/images/litlogo.png'),
        )
      ],
    ),
  );
}
//labeL
Widget bioCard(List<Widget> labelAndEdit , Widget value, Color bgColor){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
      padding: EdgeInsets.only(top: 15.0, bottom: 15.0, left: 10 , right: 10),
      child: Column(
        children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labelAndEdit
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Container(
                    padding: EdgeInsets.fromLTRB(0 , 15 , 0 , 0),
                    child: value
                ))
              ]
          )
        ],
      ),
    ),
  );
}

Widget userThumbnailAppbar(String url){
  return CachedNetworkImage(
    height: 50,
    width: 50,
    imageUrl: url,
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    ),
    placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
    errorWidget: (context, url, error) => nullUrl(),
  );
}
Widget settingCardSwitch(String label , String value, Widget switchWidget, Color bgColor , Color labelCol , Color textCol){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            child:
            Text(label ,style: infoLabel(labelCol),),
            padding: EdgeInsets.fromLTRB(0 , 5 , 0 , 0),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Container(
                        padding: EdgeInsets.fromLTRB(0 , 10 , 0 , 0),
                        child: Text(value , style: infoValue(textCol),)
                    )
                ),
                switchWidget
              ]
          )
        ],
      ),
    ),
  );
}
Widget infoCard(String label , String value , IconData icon , Color bgColor , Color labelCol , Color textCol){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            child:
            Text(label ,style: infoLabel(labelCol),),
            padding: EdgeInsets.fromLTRB(0 , 5 , 0 , 0),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Container(
                    padding: EdgeInsets.fromLTRB(0 , 10 , 0 , 0),
                    child: Text(value ?? "" , style: infoValue(textCol),)
                )
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0 , 0 , 0 , 0),
                  margin: EdgeInsets.fromLTRB(0 ,0 , 15 , 15),
                  child:Icon(icon, color: labelCol),
                )
              ]
          )
        ],
      ),
    ),
  );
}
//
Widget editableBioCard(List<Widget> labelAndEdit , Widget value, Color bgColor){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
      padding: EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labelAndEdit
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Container(
                  child: value
                ))
              ]
          )
        ],
      ),
    ),
  );
}

Widget editableInfoCard(Widget label , Widget value, Color bgColor){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
      padding: EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [label]
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Container(
                    child: value
                ))
              ]
          )
        ],
      ),
    ),
  );
}

Widget editableLituationInfoCard(Widget label ,Widget hint, Widget value, Color bgColor){
  return Card(
    color: bgColor,
    elevation: 3,
    child: Container(
      margin: EdgeInsets.fromLTRB(0, 10, 10, 15),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
              label,
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Container(
                    child: value
                ))
              ]
          ),
          hint,
        ],
      ),
    ),
  );
}

Widget infoSectionHeader(String title , Color c){
  return Container(
    margin: EdgeInsets.only(top: 25 , left: 5),
    height: 35,
    width: double.infinity,
    child:
    Text(title ,style: infoLabel(c),textAlign: TextAlign.left, textScaleFactor: 1.2,),
  );
}

Widget pageTitle(String title , Color c){
  return Container(
    child: Text(title , textAlign: TextAlign.center, style: TextStyle(color: c),textScaleFactor: 1.2,),
  );
}

Widget lituationCardLabel(String title , Color c){
  return Container(
    child: Text(title , textAlign: TextAlign.center, style: infoLabel(c),),
  );
}

Widget lituationCardHint(String hint , Color c){
  return Container(
    child: Text(hint , textAlign: TextAlign.center, style: TextStyle(color: c),textScaleFactor: 0.8,),
  );
}

Widget viewList(BuildContext context, String viewer, List data, List<Widget> removeButtons , String listname , Color labelCol){
  if(data.length != null && data.length > 0) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 35,
                width: double.infinity,
                child: Text(listname,
                  style: infoValue(labelCol),
                  textAlign: TextAlign.left,),
                padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
              ),
            ),
            Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                )
            ),
          ],
        )
        ,
        Expanded(
          //padding: EdgeInsets.all(0),
          // height: 185,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (ctx, idx) {
                return Container(
                    margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    width: 150,
                    child: Stack(
                      children: [
                        lituationDetailCard(context ,viewer, data[idx]['eventID'],
                            data[idx]['thumbnail'][0], data[idx]['title'],
                            parseDate(data[idx]['date']),
                            data[idx]['entry']),
                        Positioned(child: removeButtons[idx],
                          top: 10,
                          right: 10,
                        )
                      ],
                    )
                );
              }
          ),
        )
      ],
    );
  }
}
Widget viewListVisitor(BuildContext context, String viewer, List data, List<Widget> removeButtons , String listname , Color labelCol){
  if(data.length != null || data.length > 0) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 35,
                width: double.infinity,
                child: Text(listname,
                  style: infoValue(labelCol),
                  textAlign: TextAlign.left,),
                padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
              ),
            ),
            Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                )
            ),
          ],
        )
        ,
        Expanded(
          //padding: EdgeInsets.all(0),
          // height: 185,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (ctx, idx) {
                return Container(
                    margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    width: 150,
                    child: Stack(
                      children: [
                        lituationDetailCard(context , viewer , data[idx]['eventID'],
                            data[idx]['thumbnail'][0], data[idx]['title'],
                            parseDate(data[idx]['date']),
                            data[idx]['entry']),
                      ],
                    )
                );
              }
          ),
        )
      ],
    );
  }
}
Widget loadingWidget(BuildContext context){
  return CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor),);
}
Widget placeResultTile(BuildContext context, PlacesSearchResult suggestion){
  return  ListTile(
    tileColor: Theme.of(context).scaffoldBackgroundColor,
    contentPadding: EdgeInsets.all(5),
    leading: Image.asset('assets/images/litlocationicon.png'),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(suggestion.name , style: TextStyle(color: Theme.of(context).primaryColor , decoration: TextDecoration.none , fontSize: 14)),
        Padding(padding: EdgeInsets.only(bottom: 10)),
        Text(suggestion.formattedAddress , style: TextStyle(color: Theme.of(context).textSelectionColor , decoration: TextDecoration.none , fontSize: 12.5)),

      ],
    ),
  );
}
Marker googleMapMarker(String title , BitmapDescriptor icon , LatLng pos){
  return Marker(
    markerId: MarkerId(title),
    position: pos,
    icon: icon,
  );
}
Widget nullLituationUrl(){
  return Container(
    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    width: 175.0,
    height: 150.0,
    decoration: BoxDecoration(
      shape: BoxShape.rectangle,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.8,
          child: Image.asset('assets/images/litlogo.png'),
        )
      ],
    ),
  );
}


Widget lituationCategoryResultTile(String suggestion , BuildContext context){
  return ListTile(
    contentPadding: EdgeInsets.all(15),
    leading: Image.asset(logo),
    title: Text(suggestion , style: TextStyle(color: Theme.of(context).textSelectionColor , decoration: TextDecoration.none),),
  );
}
Widget userResultTile(String username , String profile , BuildContext context){
  return Container(
    margin: EdgeInsets.only(left: 5, right: 5),
    child: Card(
      elevation: 3,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: userProfileThumbnail(profile, 'online'),
        title: Text(username , style: TextStyle(color: Theme.of(context).textSelectionColor , decoration: TextDecoration.none),),
      ),
    ),
  );
}
Widget userSearchResultTile(String username , String profile , Widget vibing, BuildContext context){
  return Card(
    elevation: 3,
    color: Theme.of(context).scaffoldBackgroundColor,
    child: ListTile(
      contentPadding: EdgeInsets.all(10),
      leading: userProfileThumbnail(profile, 'online'),
      title: Text(username , style: TextStyle(color: Theme.of(context).textSelectionColor , decoration: TextDecoration.none),),
      subtitle: vibing
    ),
  );
}

Widget lituationResultCard(BuildContext ctx, DocumentSnapshot l){
  return Card(
    color: Theme.of(ctx).scaffoldBackgroundColor,
    elevation: 3,
      child:  Container(
        width: 225,
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Expanded(
             flex: 6,
             child:  CachedNetworkImage(
             imageUrl: l.data()['thumbnail'][0],
             imageBuilder: (context, imageProvider) => Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(5),
                 image: DecorationImage(
                   image: imageProvider,
                   fit: BoxFit.cover,
                 ),
               ),
             ),
             placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).buttonColor),),
             errorWidget: (context, url, error) => nullUrl(),
           ),),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lituationDateDocumentSnapshotWidget(ctx , l)),
                Expanded(
                  child: Text(l.data()['title'] , style: TextStyle(color: Colors.white , fontSize: 14 ,fontWeight: FontWeight.w900),textAlign: TextAlign.center,),
                )
              ],
            ),
            Expanded(
              flex: 1,
              child: Text(l.data()['entry'] , style: TextStyle(color: Colors.white , fontSize: 12 ,fontWeight: FontWeight.w500),textAlign: TextAlign.center,),
            ),
            Expanded(
              flex: 2,
              child: Text(parseDate(l.data()['date']) , style: TextStyle(color: Colors.white , fontSize: 12 ,fontWeight: FontWeight.w500),textAlign: TextAlign.center,),
            ),
          ],
        ),
      )
  );
}

Widget lituationDateWidget(BuildContext context , Lituation l){
  List months = ['Jan', 'Feb', 'Mar', 'Apr', 'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  DateTime date = l.date;
  String month = months[date.month - 1];
  String day = date.day.toString();
  return Container(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 1,child: Text(day, style: TextStyle(fontWeight: FontWeight.w600,color: Theme.of(context).textSelectionColor), textScaleFactor: 1.6,)),
        Expanded(flex: 1,child: Container(margin: EdgeInsets.only(top: 10) ,child:Text(month, style: TextStyle(fontWeight: FontWeight.w200,color: Theme.of(context).textSelectionColor), textScaleFactor: 1,),)),
        Expanded(flex: 2,child: Container(margin: EdgeInsets.only(top: 10) ,child: userProfileThumbnail(l.host?.profileURL ?? "https://via.placeholder.com/150/FF0000/FFFFFF?text=Loading" , 'online'),)),
      ],
    ),
  );
}
Widget lituationDateDocumentSnapshotWidget(BuildContext context , DocumentSnapshot l){
  List months = ['Jan', 'Feb', 'Mar', 'Apr', 'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  DateTime date = DateTime.fromMicrosecondsSinceEpoch(l.data()['date'].millisecondsSinceEpoch * 1000);
  String month = months[date.month - 1];
  String day = date.day.toString();
  return Container(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(child: Text(day, style: TextStyle(fontWeight: FontWeight.w600,color: Theme.of(context).textSelectionColor), textScaleFactor: 1.6,)),
        Container(child: Text(month, style: TextStyle(fontWeight: FontWeight.w200,color: Theme.of(context).textSelectionColor), textScaleFactor: 1,)),
        Container(margin: EdgeInsets.only(top: 10),child: userProfileThumbnail(l.data()['hostID'] , 'online'),),
      ],
    ),
  );
}
Widget lituationThumbnailWidget(Lituation l){
  return CachedNetworkImage(
    imageUrl: l.thumbnailURLs != null && l.thumbnailURLs.length > 0 ? l.thumbnailURLs[0] : "https://via.placeholder.com/150/FF0000/FFFFFF?text=Loading",
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    ),
    placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).buttonColor),),
    errorWidget: (context, url, error) => nullLituationUrl(),
  );
}
Widget lituationDetailCard(BuildContext ctx ,String visitorID , String lID , String thumbnail , String title , String date , String entry){
  return GestureDetector(
    onTap: (){
     _viewLituation(ctx, visitorID, lID, title);
    },
    child: Card(
      elevation: 3,
      child:  Stack(
        children: [
          Opacity(
            opacity: 1,
            child:  CachedNetworkImage(
              imageUrl: thumbnail,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).buttonColor),),
              errorWidget: (context, url, error) => nullUrl(),
            ),
          ),
          Positioned(
              left: 0,
              right: 0,
              bottom: 5,
              child: Container(
                color: Colors.black26,
                height: 75,
                child: Column(
                  children: [
                    Expanded(
                      child: Text(title , style: TextStyle(color: Colors.white , fontSize: 14 ,fontWeight: FontWeight.w900),textAlign: TextAlign.center,),
                    ),
                    Expanded(
                      child: Text(entry , style: TextStyle(color: Colors.white , fontSize: 12 ,fontWeight: FontWeight.w500),textAlign: TextAlign.center,),
                    ),
                    Expanded(
                      child: Text(date , style: TextStyle(color: Colors.white , fontSize: 12 ,fontWeight: FontWeight.w500),textAlign: TextAlign.center,),
                    ),
                  ],
                ),
              )
          )
        ],
      ),
    ),
  );
}
void _viewLituation(BuildContext context,String userID , String lID , String lName){
  LituationVisit lv = LituationVisit();
  lv.userID = userID;
  lv.lituationID = lID;
  lv.lituationName = lName;
  Navigator.pushNamed(context, ViewLituationRoute , arguments: lv);
}
Widget lituationCard(Lituation l, BuildContext context) {    
  return Container(
      child: GestureDetector(
        onTap: () async {          
            LituationVisit lv = LituationVisit();
            lv.userID = l.hostID;
            lv.lituationID = l.eventID;
            lv.lituationName = l.title;
            Navigator.pushNamed(context, ViewLituationRoute , arguments: lv);
          },
        child: Card(
          color: Theme.of(context).backgroundColor,
          elevation: 5,
          child: Container(
            padding: EdgeInsets.only(bottom: 10),
            height: 325,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5,child: lituationThumbnailWidget(l),),
                Expanded(flex: 3,child: lituationInfoRow(l, context),)
              ],
            ),
          ),
        ),
      )
  );
}
Widget lituationInfoRow(Lituation l, BuildContext context){
  return Container(
    margin: EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Expanded(flex: 2,child: lituationDateWidget(context , l),),
        Expanded(flex: 6,child: lituationInfoCardWidget(l, context),),
      //TODO Make row below address
        Expanded(flex: 3,child: lituationResultStatusCard(l, context),),
      ],
    ),
  );
}
Widget lituationInfoCardWidget(Lituation l, BuildContext context){
  return Container(
    margin: EdgeInsets.only(top: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(l.title , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 1.2,),),
        Expanded(child: Text(parseThemes(l) , textScaleFactor: 0.7 , style: TextStyle(color: Colors.blueAccent),),),
        Expanded(child: lituationTimeWidget(l, context),),
        Expanded(child: Text(l.title , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 0.7,),),
      ],
    ),
  );
}
//shows time from 2 time stamps
Widget lituationTimeWidget(Lituation l, BuildContext context){
  String st = parseTime(Timestamp.fromDate(l.date));
  String et = parseTime(Timestamp.fromDate(l.end_date));
  String day = parseDay(true, Timestamp.fromDate(l.date));
  return Text(
      '$day,$st - $et' , style: infoValue(Theme.of(context).textSelectionColor),
  );
}
Widget lituationResultStatusCard(Lituation l, BuildContext context){
  return Container(
    margin: EdgeInsets.only(right: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
            text: TextSpan(
                text: parseVibes(l.vibes.length.toString()),style: infoValue(Theme.of(context).textSelectionColor),
                children: [
                  TextSpan(text: ' vibes going\n' , style: infoValue(Theme.of(context).primaryColor))
                ]
            )
        ),
        RichText(
            text: TextSpan(
                text: lituation_result_entry_label,style: infoValue(Theme.of(context).textSelectionColor),
                children: [
                  TextSpan(text: l.entry + '\n' , style: infoValue(Theme.of(context).primaryColor))
                ]
            )
        ),
        RichText(
            text: TextSpan(
                text: 'capacity: ',style: infoValue(Theme.of(context).textSelectionColor),
                children: [
                  TextSpan(text: l.capacity , style: infoValue(Theme.of(context).primaryColor))
                ]
            )
        ),
      ],),
  );
}
Widget nullList(String username , String listname , Color c){
  return Column(
      children: [
        Container(
          height: 35,
          width: double.infinity,
          child: Text(listname,
            style: infoValue(c),
            textAlign: TextAlign.left,),
          padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
        ),
        Container(
          height: 150,
          alignment: Alignment.center,
          child: Center(child: Text( username + ' has no ' + listname , style: TextStyle(color: c),),),
        )
      ]);
}
Color status(String data){
  if(data.contains('online')){
    return Colors.lightGreenAccent;
  }
  return Colors.red;
}
Widget userProfileThumbnail(String url ,  String stat) {
  return Container(
    margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
    child: CachedNetworkImage(
      height: 45,
      width: 45,
      imageUrl: url,
      imageBuilder: (context, imageProvider) =>
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: status(stat)),
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
      placeholder: (context, url) =>
          CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Theme
                .of(context)
                .splashColor),),
      errorWidget: (context, url, error) => nullUrl(),
    ),
  );
}
