
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Extensions/search_filters.dart';
import 'package:lit_beta/Providers/SearchProvider/search_provider.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:lit_beta/Styles/theme_resolver.dart';

class SearchPage extends StatefulWidget {
  final String userID;
  SearchPage({Key key , this.userID}) : super(key: key);
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<SearchPage> {
  var vibeResults = [];
  var lituationResults = [];
  int _searchTabIdx = 0;
  String lituation_search_filter;
  TextEditingController vibesSearchController;
  TextEditingController lituationsSearchController;
  SearchProvider sp;
  @override
  void dispose(){
    super.dispose();
  }

  @override
  void initState() {
    lituation_search_filter = BY_TITLE;
    vibesSearchController = new TextEditingController();
    lituationsSearchController = new TextEditingController();
    sp = new SearchProvider(widget.userID);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: searchWidget()
    );

  }

  Widget searchWidget(){
    return Stack(
      children: [
        searchIndexedStackProvider(),
        Align(alignment: Alignment.topCenter,child: searchTabs(),)
      ],
    );
  }
  Widget searchIndexedStackProvider(){
    return Column(
      children: [
        Expanded(child: IndexedStack(
          index: _searchTabIdx,
          children: [
            vibesSearchWidget(),
            lituationSearchWidget()
          ],
          )
        )
      ],
    );
  }
  Widget searchTabs(){
    return Container(
      width: 250,
      margin: EdgeInsets.only(top: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: tappableTab('Vibes', 0)),
          Expanded(child: tappableTab('Lituations', 1)),
        ],
      ),
    );
  }

  Widget vibesSearchWidget(){
    return Column(
      children: [
        searchBar(),
        vibeResultList(),
      ],
    );
  }
  //lituationResults
  Widget lituationSearchWidget(){
    return Column(
      children: [
        lituationSearchBar(),
        lituationResultList(),
      ],
    );
  }
  Widget lituationResultList(){
    if(lituationResults.length < 1 && lituationsSearchController.text.length > 0){
      return Container(
        margin: EdgeInsets.all(15),
        child: Card(
          elevation: 3,
          color: Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Text("No lituations found...Try someone else." , style: infoLabel(Theme.of(context).textSelectionColor),),
          ),
        ),
      );
    }
    return Expanded(
        child: ListView.builder(
          itemCount: lituationResults.length,
          itemBuilder: (context , idx){
            return  lituationResults[idx];
          },
        )
    );
  }
  Widget vibeResultList(){
    if(vibeResults.length < 1 && vibesSearchController.text.length > 1){
      return Container(
        margin: EdgeInsets.all(15),
        child: Card(
          elevation: 3,
          color: Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Text("No users found...Try someone else." , style: infoLabel(Theme.of(context).textSelectionColor),),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: vibeResults.length,
        itemBuilder: (context , idx){
          return  vibeResults[idx];
        },
      )
    );
  }
  Widget tappableTab(String title, int idx){
    Color c = Theme.of(context).buttonColor;
    Widget indicator = Container();
    var scale = 0.8;
    if(idx == _searchTabIdx){
      scale = 1.1;
      indicator = selectedIndicator(Theme.of(context).textSelectionColor);
      c = Theme.of(context).textSelectionColor;
    }
    return Container(
        height: 35,
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(flex: 9,child: Text(title , style: TextStyle(color: c), textAlign: TextAlign.center, textScaleFactor: scale,),),
              indicator
            ],
          ),
          onTap: (){
            setState(() {
              _searchTabIdx = idx;
            });
          },
        )
    );
  }
  Widget searchBar(){
    return Container(
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      margin: EdgeInsets.only(top: 85 , left: 15 , right: 15),
      child: TextField(
        cursorColor: Theme.of(context).textSelectionColor,
        style: TextStyle(
            color: Theme.of(context).textSelectionColor),
        controller: vibesSearchController,
        decoration: InputDecoration(
            labelStyle: TextStyle(color: Theme.of(context).textSelectionColor),
            labelText: vibes_search_hint,
            suffixIcon: new Icon(Icons.search ,
              color: Theme.of(context).primaryColor,
            ),
            prefixIcon: vibesSearchController.text.isNotEmpty?GestureDetector(
              child: new Icon(Icons.clear ,
                color: Theme.of(context).textSelectionColor,
              ),
              onTap: (){vibesSearchController.clear();},
            ):Container(width: 0),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
              borderSide: BorderSide(color: Colors.transparent , width: 0),),
            focusedBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: Theme.of(context).buttonColor , width: 1))
        ),
        onChanged: (value) async {
          vibeResults.clear();
          var res = [];
          await sp.searchUser(vibesSearchController.text).then((users) async {
         setState(() {
           for(var u in users){
             if(u.data()['username'].toString().toLowerCase().contains(value.toLowerCase())){
               if(!res.contains(u.data()['userID'])){
                 //String status = await sp.getVibingStatus(u.data()['userID']);
                 res.add(u.data()['userID']);
                 vibeResults.add(userResultTile(u.data()['username'],u.data()['profileURL'], context));
               }
             }else{
               vibeResults.clear();
             }
           }
         });
          });
        },
      ),
    );
  }

  Widget lituationResult(String lID){
    String url;
    return StreamBuilder(
        stream: sp.getLituation(lID),
        builder: (ctx , l){
          if(!l.hasData || l.connectionState == ConnectionState.waiting){
            return Container();
          }
          return Container(
              child: GestureDetector(
                onTap: (){
                  //_viewLituation(lID , l.data['title']);
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
                        Expanded(flex: 3,child: lituationInfoRow(l),)
                      ],
                    ),
                  ),
                ),
              )
          );
        }
    );
  }
  Widget lituationInfoRow(AsyncSnapshot l){
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(flex: 2,child: lituationDateWidget(l),),
          Expanded(flex: 6,child: lituationInfoCardWidget(l),),
        //TODO Make row below address
          Expanded(flex: 3,child: lituationResultStatusCard(l),),
        ],
      ),
    );
  }
  Widget lituationInfoRow2(AsyncSnapshot l){
    return Container(
      child: Column(
        children: [
         Expanded(child:          Row(
   children: [
     lituationDateWidget(l),
     lituationInfoCardWidget(l),
     lituationResultStatusCard(l),
   ],
 ),),

        ],
      )
    );
  }
  Widget lituationInfoCardWidget(AsyncSnapshot l){
    return Container(
      margin: EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(l.data['title'] , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 1.2,),),
          Expanded(child: Text(parseThemes(l) , textScaleFactor: 0.7 , style: TextStyle(color: Colors.blueAccent),),),
          Expanded(child: lituationTimeWidget(l),),
          Expanded(child: Text(l.data['location'] , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 0.7,),),
        ],
      ),
    );
  }
  //shows time from 2 time stamps
  Widget lituationTimeWidget(AsyncSnapshot l){
    String st = parseTime(l.data['date']);
    String et = parseTime(l.data['end_date']);
    String day = parseDay(true, l.data['date']);
    return Text(
        '$day,$st - $et' , style: infoValue(Theme.of(context).textSelectionColor),
    );
  }
  Widget lituationResultStatusCard(AsyncSnapshot l){
    return Container(
      margin: EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                  text: parseVibes(List.from(l.data['vibes']).length.toString()),style: infoValue(Theme.of(context).textSelectionColor),
                  children: [
                    TextSpan(text: ' vibes going\n' , style: infoValue(Theme.of(context).primaryColor))
                  ]
              )
          ),
          RichText(
              text: TextSpan(
                  text: lituation_result_entry_label,style: infoValue(Theme.of(context).textSelectionColor),
                  children: [
                    TextSpan(text: l.data['entry'] + '\n' , style: infoValue(Theme.of(context).primaryColor))
                  ]
              )
          ),
          RichText(
              text: TextSpan(
                  text: 'capacity: ',style: infoValue(Theme.of(context).textSelectionColor),
                  children: [
                    TextSpan(text: l.data['capacity'] , style: infoValue(Theme.of(context).primaryColor))
                  ]
              )
          ),
        ],),
    );
  }
  Widget lituationDateWidget(AsyncSnapshot l){
    List months = ['Jan', 'Feb', 'Mar', 'Apr', 'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    DateTime date = DateTime.fromMicrosecondsSinceEpoch(l.data['date'].millisecondsSinceEpoch * 1000);
    String month = months[date.month - 1];
    String day = date.day.toString();
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(child: Text(day, style: TextStyle(fontWeight: FontWeight.w600,color: Theme.of(context).textSelectionColor), textScaleFactor: 1.6,)),
          Container(child: Text(month, style: TextStyle(fontWeight: FontWeight.w200,color: Theme.of(context).textSelectionColor), textScaleFactor: 1,)),
          Container(margin: EdgeInsets.only(top: 10),child: userProfileThumbnail(l.data['hostID'] , 'online'),),
        ],
      ),
    );
  }
  Widget lituationThumbnailWidget(AsyncSnapshot l){
    return CachedNetworkImage(
      imageUrl: l.data['thumbnail'][0].toString(),
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

  Widget lituationSearchBar(){
    return Container(
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      margin: EdgeInsets.only(top: 85 , left: 15 , right: 15),
      child: TextField(
        cursorColor: Theme.of(context).textSelectionColor,
        style: TextStyle(
            color: Theme.of(context).textSelectionColor),
        controller: lituationsSearchController,
        decoration: InputDecoration(
            labelStyle: TextStyle(color: Theme.of(context).textSelectionColor),
            labelText: lituations_search_hint,
            suffixIcon: new Icon(Icons.search ,
              color: Theme.of(context).primaryColor,
            ),
            prefixIcon: lituationsSearchController.text.isNotEmpty?GestureDetector(
              child: new Icon(Icons.clear ,
                color: Theme.of(context).textSelectionColor,
              ),
              onTap: (){lituationsSearchController.clear();},
            ):Container(width: 0),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
              borderSide: BorderSide(color: Colors.transparent , width: 0),),
            focusedBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: Theme.of(context).buttonColor , width: 1))
        ),
        onChanged: (value)  async {
            setState(() {
              lituationResults.clear();
            });
            await sp.searchLituation(value, BY_TITLE).then((res){
            for(var l in res){
              print(l.data()['title']);
              setState(() {
                lituationResults.add(lituationResult(l.data()['eventID']));
              });
            }
            });
        },
      ),
    );
  }
  Widget cloutBadge(String clout){
    String v = '';
    return Text(clout , style: infoValue(Theme.of(context).primaryColor),);
  }
}
