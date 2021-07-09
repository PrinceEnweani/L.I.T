
import 'dart:async';
import 'dart:io';

import 'package:carousel_pro/carousel_pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/common_maps_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';

class PreviewLituationPage extends StatefulWidget{
  final Lituation newLituation;
  PreviewLituationPage({Key key , this.newLituation}) : super(key: key);

  @override
  _PreviewLituationPageState createState() => new _PreviewLituationPageState();

}
class _PreviewLituationPageState extends State<PreviewLituationPage>{
  final Auth db = Auth();
  List<String> lituationMediaFiles = List();
  List lituationMediaWidgets = List();
  bool isSaving = false;
  LituationProvider lp;

  @override
  void dispose(){
    super.dispose();
  }
  void initState(){
    lp = LituationProvider("preview" , widget.newLituation.hostID);
    initLituationMedia();
    super.initState();
  }
  void initLituationMedia(){
    for(String path in widget.newLituation.thumbnailURLs){
      if(path != null && path != "") {
        setState(() {
        print(path);
        File f = File(path);
        lituationMediaFiles.add(path);
        lituationMediaWidgets.add(new Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: new BoxDecoration(
              image: new DecorationImage(
                fit: BoxFit.cover,
                image: FileImage(f),
              )
          ),
        ));

        });
      }
    }
    if(lituationMediaWidgets.isEmpty){
      lituationMediaWidgets.add(new Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: new BoxDecoration(
            image: new DecorationImage(
              fit: BoxFit.scaleDown,
              image: AssetImage('assets/images/litlogolabeled.png'),
            )
        ),
      ));
    }
  }
  Widget lituationTitleWidget(String title){
   return Card(
     elevation: 5,
     color:  Theme.of(context).scaffoldBackgroundColor,
     child: Align(
       child: Container(
         padding: EdgeInsets.fromLTRB(0, 0, 0, 50),
         child: Column(children: [
           Container(
             padding: EdgeInsets.fromLTRB(15, 25, 15, 15),
             child: Text(title , style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 24),textAlign: TextAlign.center,),
           ),
           StreamBuilder(
             stream: db.getUser(widget.newLituation.hostID),
             builder: (ctx, u){
               return !u.hasData
                   ?new Text("loading" , style: TextStyle(color: Theme.of(context).textSelectionColor),)
                   : Container(padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                 child: Text('by ' + u.data['username'] ,style:
                 TextStyle(color: Theme.of(context).textSelectionColor ,fontWeight: FontWeight.w900 ,decoration: TextDecoration.underline),textAlign: TextAlign.center,),);
             },
           ),
           Container(
             padding: EdgeInsets.all(15.0),
             alignment: Alignment.topLeft,
             child: Text("Description:" ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),
           ),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Flexible(
                   child: Container(
                     padding: EdgeInsets.fromLTRB(15 , 10 , 15 , 0),
                     child: Text(widget.newLituation.description,style: TextStyle(color: Theme.of(context).dividerColor , fontSize: 14),textAlign: TextAlign.left,),
                   )
               ),
             ],
           ),
         ],),
       )
     )
   );
  }
  Widget aboutRow(String entry , DateTime date , String vibing){
    String str;
    if(date == null){
      str = 'TBD';
    }else{
      str = DateFormat.yMd().addPattern('\n').format(date);
    }

    return Card(
      elevation: 5,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){

                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(MaterialCommunityIcons.door , color: Theme.of(context).primaryColor,),
                        Text(entry, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                      ],
                    )
                )
            ),
          ),
          Expanded( //lo
              child:    GestureDetector(
                  onTap: (){},
                  child: Container(
                      margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      padding: EdgeInsets.all(10.0),
                      child:  Column(
                        children: [
                          Icon(Icons.calendar_today , color: Theme.of(context).primaryColor,),
                          Text(str, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                        ],
                      )
                  )
              )
          ),
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){

                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(Icons.people , color: Theme.of(context).primaryColor,),
                        Text(vibing + ' vibed', style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14), textAlign: TextAlign.center,),
                      ],
                    )
                )
            ),
          )

        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    Lituation l = widget.newLituation;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: previewLituationNav(context),
        body: ListView(
          padding: EdgeInsets.fromLTRB(0,0, 0, 50),
          children: <Widget>[
            SizedBox(
                height: 300.0,
                width: 375.0,
                child: Carousel(
                  images: lituationMediaWidgets,
                  dotSize: 4.0,
                  dotSpacing: 15.0,
                  dotColor: Theme.of(context).buttonColor,
                  indicatorBgPadding: 5.0,
                  dotBgColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  borderRadius: true,
                  autoplay: false,
                  moveIndicatorFromBottom: 180.0,
                  noRadiusForIndicator: true,
                )
            ),
            aboutRow(l.entry, l.date, '0'),
            lituationTitleWidget(l.title),
            lituationInfo("Time:", DateFormat.jm().format(l.date) + " - " + DateFormat.jm().format(l.end_date)  , Icons.access_time),
            lituationInfo("Address:", checkTBD(l.location) , Icons.location_on),
            lituationInfo("Entry" , l.entry , MaterialCommunityIcons.door),
            lituationInfo('Capacity' , capacityChecker(l.capacity.toString()) , Icons.person),
            postLituation(context),
            saveLituation(context),
          ],
        ),
        

      ),
    );
  }

  String capacityChecker(String capacity){
    if(capacity == null || capacity == ''){
      return 'N/A';
    }else{
      return capacity;
    }
  }

 String checkTBD(String val){
    if(val ==""){
      return "TBD";
    }
    return val;
 }

  Widget postLituation(BuildContext ctx){
    return Container( //login button
        height: 45,
        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
        padding: EdgeInsets.fromLTRB(75, 0, 75, 0),
        child: RaisedButton(
            color: Theme.of(context).buttonColor,
            textColor: Theme.of(context).primaryColor,
            child: isSaving ? CircularProgressIndicator() : Text('Post'),
            onPressed: isSaving ? null : (){
              _createNewLituation(widget.newLituation , ctx);
            }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(25.0))
        ));
  }
  Widget saveLituation(BuildContext ctx){
    if (isSaving) {
      //TODO replace with Animated spinner
      return Container(padding: EdgeInsets.all(0), child: Text("please wait..." , style: infoLabel(Theme.of(context).textSelectionColor), textAlign: TextAlign.center,),);
    }
    return Container( //login button
        height: 45,
        margin: EdgeInsets.fromLTRB(0, 25, 0, 0),
        padding: EdgeInsets.fromLTRB(75, 0, 75, 0),
        child: RaisedButton(
            color: Theme.of(context).buttonColor,
            textColor: Theme.of(context).primaryColor,
            child: isSaving ? CircularProgressIndicator() : Text('Save as draft' , style: infoValue(Theme.of(context).textSelectionColor)),
            onPressed: isSaving ? null : (){
              _saveAsDraft(widget.newLituation, ctx);
              //nextPage(ctx);
            }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(25.0))
        ));
  }
  Future<bool> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text('Discard your changes?' ,style: TextStyle(color: Theme.of(context).buttonColor),),
            actions: <Widget>[
              FlatButton(
                child: Text('No' ,style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FlatButton(
                child: Text('Yes' ,style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  Widget previewLituationNav(BuildContext ctx){
    return AppBar(
      leading: Container(
        padding: EdgeInsets.all(10),
        child:  IconButton(
          icon: Icon(Icons.edit,color: Theme.of(context).buttonColor,size: 25,
          ),
          onPressed: (){Navigator.of(ctx).pop();},
        ),
      ) ,
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      title: Container(
          padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
          child: Text('Confirm your Lituation' , style: TextStyle(color: Theme.of(context).buttonColor),)
      ),
      actions: [
        Container(
          padding: EdgeInsets.all(10),
          child:  IconButton(
            icon: Icon(Icons.more_vert,color: Theme.of(context).buttonColor,size: 25,
            ),
            onPressed: (){},
          ),
        ) ,

      ],
    );
  }

  _createNewLituation(Lituation l , BuildContext ctx) async{
    setState(() {
      isSaving = true;
    });
    l.thumbnailURLs = lituationMediaFiles;
    l.observers = [l.hostID];
    l.pending = [];
    l.musicGenres = [];
    l.requirements = [];
    l.specialGuests = [];
    l.status = 'pending';
    if(l.entry != 'Fee' && (l.fee == null || l.fee != '0')){
      l.fee = '';
    }
    lp.createNewLituation(l).then((value){
      //_toProfile(l.hostID);
      setState(() {
        isSaving = false;
      });
      if(value != null) {
        _viewLituation(value, l.title);
      }
    });
}

  void _viewLituation(String lID , String lName){
    LituationVisit lv = LituationVisit();
    lv.userID = widget.newLituation.hostID;
    lv.lituationID = lID;
    lv.lituationName = lName;
    lv.action = "edit";
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, ViewLituationRoute , arguments: lv);
  }

  _saveAsDraft(Lituation l , BuildContext ctx) async{
    setState(() {
      isSaving = true;
    });
    l.thumbnailURLs = lituationMediaFiles;
    l.observers = [l.hostID];
    l.pending = [];
    l.musicGenres = [];
    l.requirements = [];
    l.specialGuests = [];
    l.status = 'draft';
    if(l.fee != null && l.fee != 0){

    }
    lp.createNewDraft(l).then((value){
      setState(() {
        isSaving = false;
      });
      _toProfile(l.hostID);
    });
  }
  void _toProfile(String uID){
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Widget lituationDescription(BuildContext ctx){
    return Card(
      elevation: 10,
      margin: EdgeInsets.fromLTRB(0 ,25 , 0 , 25),
      color: Theme.of(context).primaryColor,
      child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          decoration: BoxDecoration(
            //border: Border.all(color: primaryColor),
            borderRadius: BorderRadius.circular(15),
          ) ,
          child: Column(
            children: [
              Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 25),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.0),
                              alignment: Alignment.topLeft,
                              child: Text("Description:" ,style: TextStyle(color: Theme.of(context).buttonColor),textAlign: TextAlign.left,),
                            ),
                            Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              alignment: Alignment.topLeft,
                              child: Text(widget.newLituation.description ,style: TextStyle(color: Theme.of(context).buttonColor),textAlign: TextAlign.left,),
                            ),

                          ],
                        ),

                      ),
                    ],
                  )
              ),


            ],
          )

      ),
    );
  }

  Widget lituationInfo(String title , String value , IconData icon){
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 10,
      child:  Container(
          margin: EdgeInsets.fromLTRB(10 ,10 , 10 , 0),
          child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10.0 , 10 , 25, 25),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Expanded(child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Container(
                       padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                       child: Text(title ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
                     Container(
                       padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                       margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                       child:Text(value ,style: TextStyle(color: Theme.of(context).dividerColor),textAlign: TextAlign.start,),),
                   ],
                 ),),

                Container(
                    padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
                    child:  Icon(icon, color: Theme.of(context).primaryColor, size: 25,)
                ),
              ],
            ),

          ),
        ],
      )
      ),
    );
  }
}