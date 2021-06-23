import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/Vibes.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Models/User.dart' as UserModel;
import 'package:lit_beta/Strings/settings.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'DBA.dart';
import 'custom_web_view.dart';

class Auth implements DBA {
  final FirebaseAuth dbAuth = FirebaseAuth.instance;
  final FirebaseFirestore dbRef = FirebaseFirestore.instance;
  final FirebaseStorage dbMediaRef = FirebaseStorage.instance;

  @override
  Future<User> getCurrentUser() async {
   return dbAuth.currentUser;
  }

  @override
  Future<bool> isVerified() async {
    return dbAuth.currentUser.emailVerified;
  }

  @override
  Future<void> sendEmailVerification() async {
    dbAuth.currentUser.sendEmailVerification();
  }

  @override
  Future<void> signOut() async {
    return dbAuth.signOut();
  }
  @override
  Future<String> signIn(String email, String password) async {
    String userID = '';
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)
          .then((value){
        updateStatus('online');
        userID = value.user.uid;
      });
    } on FirebaseAuthException catch (e){
      userID = handleAuthException(e);
    }
    return userID;
  }

  Future<UserCredential> googleAuth() async {
    try {
      // Trigger the authentication flow
      GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential u = await FirebaseAuth.instance.signInWithCredential(credential);
      await u.user.updateEmail(googleUser.email);
      return u;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<String> signInWithGoogle() async {
    String userID = '';
    try {
      await this.googleAuth().then((value) async {
          DocumentSnapshot userSnap = await this.getUserSnapShot(value.user.uid); // check user registered or not
          if (userSnap.exists == false)
            userID = auth_no_user_error_code;
          else{
            updateStatus('online');
            userID = value.user.uid;
          }
      });      
    } on FirebaseAuthException catch (e) {
      print("Google Signin Error " + e.code);
      userID = handleAuthException(e);
    }
    return userID;
  }

  Future<UserCredential> facebookAuth(context) async {
    UserCredential user;
    String result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CustomWebView(
                selectedUrl:
                    'https://www.facebook.com/dialog/oauth?client_id=$fb_app_id&redirect_uri=$fb_redirect_url&response_type=token&scope=email,public_profile,',
              ),
          maintainState: true),
    );
    if (result != null) {
      try {
        final facebookAuthCred = FacebookAuthProvider.credential(result);
        user = await FirebaseAuth.instance.signInWithCredential(facebookAuthCred);
        print('user $user');
      } catch (e) {
        print('Error $e');
        throw e;
      }
    }
    return user;
  }

  Future<String> signInWithFacebook(context) async {
    String userID = '';
    try {
      await this.facebookAuth(context).then((value) async {
          DocumentSnapshot userSnap = await this.getUserSnapShot(value.user.uid); // check user registered or not
          if (userSnap.exists == false)
            userID = auth_no_user_error_code;
          else{
            updateStatus('online');
            userID = value.user.uid;
          }
      });      
    } on FirebaseAuthException catch (e) {
      print("Google Signin Error " + e.code);
      userID = handleAuthException(e);
    }
    return userID;
  }

  Future<bool> sendPushNotification(String token, String title, String body, {var data, var tokens}) async {
    http.Response response = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$fcm_server_key',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title
          },
          'priority': 'high',
          'data': data ?? {},
          'registration_ids': token != "" ? [token] : tokens
        },
      ),
    );
    if (response.statusCode == 200)
      return true;
    return false;
  }
  Future<TaskSnapshot> changeUserProfileImage(String userID , File image){
    dbMediaRef.ref().child('userProfiles').child(userID).putFile(image).then((taskSnapshot){
      //TODO Update to .error update check
      if(taskSnapshot.ref != null){
        taskSnapshot.ref.getDownloadURL().then((value){
          final newProfileUrl = value;
          dbRef.collection("users").doc(userID).set({'profileURL': newProfileUrl},SetOptions(merge: true)).then((_){

          });
        });
      }
      return taskSnapshot;
    });
  }
  void updateStatus(String status) async {
       dbRef.collection(db_users_collection).doc(dbAuth.currentUser.uid).update({'status.status' : status});
  }


  @override
  Future<String> signUp(String email , String password) async {
    try{
    User u = (await dbAuth.createUserWithEmailAndPassword(email: email, password: password)).user;
    return u.uid;
    } on FirebaseAuthException catch (e){
     return handleAuthException(e);
    }
  }

  Stream<QuerySnapshot> getAllUsers() {
    return dbRef.collection('users').snapshots();
  }
  Stream<DocumentSnapshot> getUser(String userID) {
    return dbRef.collection('users').doc(userID).snapshots();
  }

  Stream<DocumentSnapshot> getVibing(String userID){
    return dbRef.collection('vibing').doc(userID).snapshots();
  }

  Stream<DocumentSnapshot> getVibed(String userID){
    return dbRef.collection('vibed').doc(userID).snapshots();
  }

  Future<void> updateUserClout(String userID, int newClout){
    int clout;
    dbRef.collection(db_users_collection).doc(userID).get().then((value){
      clout = int.parse(value.data()['userVibe']['clout']);
      newClout = clout + newClout;
    }).then((value){
      dbRef.collection(db_users_collection).doc(userID).update({'userVibe.clout': newClout.toString()});
    });
  }

  Future<DocumentSnapshot>  getLituationCategories() async {
    return  dbRef.collection("lituationCategories").doc("categories").get();
  }

  Future<void> updateUserPushToken(String userID, String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'deviceToken': val});
  }
  Future<void> updateUserBirthday(String userID , String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userVibe.birthday': val});
  }
  Future<void> updateUserThemePreferences(String userID , String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userVibe.lituationPrefs': val});
  }
  Future<void> updateUserGender(String userID , String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userVibe.gender': val});
  }
  Future<void> updateUserPreference(String userID , String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userVibe.preference': val});
  }
  Future<QuerySnapshot> searchUser(String username) async {
    return dbRef.collection('users').where('username', isEqualTo: username).get();
  }
  Future<QuerySnapshot> getUsers() async {
    return dbRef.collection("users").get();
  }
  Future<void> updateUserLocation(String userID , String val , LatLng point) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userLocation' : val}).then((value){
      updateUserLocationLatLng(userID, point);
    });
  }
  Future<void> updateUserLocationLatLng(String userID , LatLng val) async {
    GeoPoint g = GeoPoint(val.latitude, val.longitude);
    dbRef.collection("users").doc(userID).update({'userLocLatLng' : g});
  }

  //Settings Functions
  Future<void> setVibeVisibility(String userID , String val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'vibe_visibility': val});
  }
  Future<void> setLituationVisibility(String userID , String val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'lituatiom_visibility': val});
  }
  Future<void> setActivityVisibility(String userID , String val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'activity_visibility': val});
  }
  Future<void> setLocationVisibility(String userID , String val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'location_visibility': val});
  }
  Future<void> setLituationNotifications(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'lituation_notifications': val});
  }
  Future<void> setInvitationNotifications(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'invitation_notifications': val});
  }
  Future<void> updateUsername(String userID , String newName) async {
    dbRef.collection("users").doc(userID).update({'username' : newName});
  }
  Future<void> setGeneralNotifications(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'general_notifications': val});
  }
  Future<void> setChatNotifications(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'chat_notifications': val});
  }
  Future<void> setVibeNotifications(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'vibe_notifications': val});
  }
  Future<void> enableAdultLituations(String userID , bool val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'adult_lituations': val});
  }
  Future<void> setUserTheme(String userID , String val) async {
    dbRef.collection(db_user_settings_collection).doc(userID).update({'theme': val});
  }
  Future<void> updateUserBio(String userID , String val) async {
    dbRef.collection(db_users_collection).doc(userID).update({'userVibe.bio': val});
  }
  Future<void> updateUserAttendancePreference(String userID , String newAttendancePreference) async {
    dbRef.collection("users").doc(userID).update({'userVibe.preference' : newAttendancePreference});
  }

/*

if user is not in vibing and user is not pending: add user to pending vibing of visited, and add visited to pending vibes
* if pending vibe: remove user from visited pendingVibing and removed visited from user pendingVibed
* if already vibed: remove user from visited pending vibing and remove visited from user vibed
* handles send, cancel and remove
* */
  Future<void> sendVibeRequest(String visitor , String visited) async {
    //TODO Send notification to the visited user
    //Notification should say something like -"user x has requested to vibe with you"
    var vd = [visited];
    var vo = [visitor];
    //we add them to the list of pending vibes
    UserModel.User visitorObj = await getUserModel(visitor);
    UserModel.User vistedObj = await getUserModel(visited);
    dbRef.collection('vibing').doc(visited).get().then((value){
      List pending = List.from(value.data()['pendingVibing']);
      List vibes = List.from(value.data()['vibing']);
      if(!pending.contains(visitor) && !vibes.contains(visitor)){
        dbRef.collection('vibing').doc(visited).update(
            {'pendingVibing': FieldValue.arrayUnion(vo)}).then((value) {
          dbRef.collection('vibed').doc(visitor).update(
              {"pendingVibes": FieldValue.arrayUnion(vd)});
        });
        sendPushNotification(vistedObj.deviceToken, "Vibe Request", "${visitorObj.username} has requested to vibe with you");
      }else{
        if(pending.contains(visitor)){
          dbRef.collection('vibing').doc(visited).update({'pendingVibing': FieldValue.arrayRemove(vo)}).then((value){
            dbRef.collection('vibed').doc(visitor).update({"pendingVibes": FieldValue.arrayRemove(vd)});
          });
          sendPushNotification(vistedObj.deviceToken, "Vibe Request Approve", "${visitorObj.username} vibe with you");
        }
        if(vibes.contains(visitor)){
          dbRef.collection('vibing').doc(visited).update({'vibing': FieldValue.arrayRemove(vo)}).then((value){
            dbRef.collection('vibed').doc(visitor).update({'vibed': FieldValue.arrayRemove(vd)});
            updateClout(visited, -3);
          });
          sendPushNotification(vistedObj.deviceToken, "Vibe Remove", "${visitorObj.username} remove vibe with you");
        }
      }
    });
  }

  Future<void> addToPendingVibes(String user , String vibeID) async {
      dbRef.collection("vibed").doc(user).update({'pendingVibes': FieldValue.arrayUnion([vibeID])}).then((value){
        dbRef.collection("vibing").doc(vibeID).update({'pendingVibing': FieldValue.arrayUnion([user])});
        return;
      });
  }

 Future<void> removePendingVibe(String user ,  String vibeID) async {
    dbRef.collection("vibed").doc(user).update({'pendingVibes': FieldValue.arrayRemove([vibeID])}).then((value){
      dbRef.collection("vibing").doc(vibeID).update({'pendingVibing': FieldValue.arrayRemove([user])});
      return;
    });
 }

  Future<void> updateClout(String userID , int cloutAmt) async {
    int newClout;
    dbRef.collection("users").doc(userID).get().then((val){
      newClout = int.parse(val.data()['userVibe']['clout']);
      newClout = newClout + cloutAmt;
    }).then((value){
      dbRef.collection("users").doc(userID).update({'userVibe.clout' : newClout.toString()});
    });
  }
  Stream<DocumentSnapshot> getUserLituations(String userID){
    return dbRef.collection('users_lituations').doc(userID).snapshots();
  }
  Stream<DocumentSnapshot> getUserSettings(String userID){
    return dbRef.collection('users_settings').doc(userID).snapshots();
  }
  getUserSnapShot(String userID) async {
    return await dbRef.collection("users").doc(userID).get();
  }
  
  Future<UserModel.User> getUserModel(String userID) async {
    var snapshot = await dbRef.collection("users").doc(userID).get();
    print(snapshot.data());
    UserModel.User user = UserModel.User.fromJson(snapshot.data());
    return user;
  }
  Stream<dynamic> getAllLituations(){
    return dbRef.collection('lituations').snapshots();
  }
  Future<QuerySnapshot> getAllLituationsSnapShot() async {
    return dbRef.collection("lituations").get();
  }
  Stream<DocumentSnapshot> getLituationByID(String lituationID){
    return dbRef.collection('lituations').doc(lituationID).snapshots();
  }
  Future<DocumentSnapshot> getLituationSnapshotByID(String lituationID){
    return dbRef.collection('lituations').doc(lituationID).get();
  }


  //TODO add tumbnail update function
  Future<void> updateLituationTitle(String lID, String newTitle) async{
    await dbRef.collection("lituations").doc(lID).update({'title' : newTitle});
  }
  Future<void> updateLituationDescription(String lID, String newDesc) async{
    await dbRef.collection("lituations").doc(lID).update({'description' : newDesc});
  }
  Future<void> updateLituationDate(String lID, DateTime newDate) async{
    await dbRef.collection("lituations").doc(lID).update({'date' :  Timestamp.fromDate(newDate)});
  }
  Future<void> updateLituationEndDate(String lID, DateTime newEndDate) async{
    await dbRef.collection("lituations").doc(lID).update({'end_date' :  Timestamp.fromDate(newEndDate)});
  }
  Future<void> updateLituationCapacity(String lID, String newCapacity) async{
    await  dbRef.collection("lituations").doc(lID).update({'capacity' : newCapacity});
  }
  Future<void> updateLituationLocation(String lID, String newLocation) async{
    await dbRef.collection("lituations").doc(lID).update({'location' : newLocation});
  }
  Future<void> updateLituationLocationLatLng(String lID, LatLng newLocationLatLng) async{
    await dbRef.collection("lituations").doc(lID).update({'locationLatLng' : GeoPoint(newLocationLatLng.latitude , newLocationLatLng.longitude)});
  }
  Future<void> addLikeLituation(String userId, String lID) async {
    var data = [userId];
    await dbRef.collection('lituations').doc(lID).update({"likes": FieldValue.arrayUnion(data)});
    await dbRef.collection('lituations').doc(lID).update({"clout": FieldValue.increment(5)});
  }
  Future<void> addDislikeLituation(String userId, String lID) async {
    var data = [userId];
    await dbRef.collection('lituations').doc(lID).update({"dislikes": FieldValue.arrayUnion(data)});
    await dbRef.collection('lituations').doc(lID).update({"clout": FieldValue.increment(-3)});

  }
  Future<void> addLikeTest(String userId, String lID) async {
    var data = [userId];
   await dbRef.collection('lituations').doc(lID).get().then((value) async {
     if(value.data()['dislikes'].contains(userId)){
       await removeDislikeLituation(userId, lID);
     }
     if(!value.data()['likes'].contains(userId)){
          await dbRef.collection('lituations').doc(lID).update({"likes": FieldValue.arrayUnion(data)});
          await dbRef.collection('lituations').doc(lID).update({"clout": FieldValue.increment(5)});
        }
    });
  }

  Future<void> removeLikeLituation(String userId, String lID) async {
    var data = [userId];
    await dbRef.collection('lituations').doc(lID).update({"likes": FieldValue.arrayRemove(data)});
  }
  Future<void> addDislikeTest(String userId, String lID) async {
    var data = [userId];
    await dbRef.collection('lituations').doc(lID).get().then((value) async {
      if(value.data()['likes'].contains(userId)){
        await removeLikeLituation(userId, lID);
      }
      if(!value.data()['dislikes'].contains(userId)){
        await dbRef.collection('lituations').doc(lID).update({"dislikes": FieldValue.arrayUnion(data)});
        await dbRef.collection('lituations').doc(lID).update({"clout": FieldValue.increment(-3)});
      }
    });

  }
  Future<void> removeDislikeLituation(String userId, String lID) async {
    var data = [userId];
    await dbRef.collection('lituations').doc(lID).update({"dislikes": FieldValue.arrayRemove(data)});
  }
   Future<void> watchLituation(String userID , String lID) async{
    //TODO send notification to host if Lituation_notifications are enabled.
     //Notification should say something like "User_x is observing your Lituation_x"
    var u = [userID];
    var l = [lID];
    UserModel.User visitor = await getUserModel(userID);
    //we add them to the list of pending vibes
    dbRef.collection('lituations').doc(lID).get().then((value) async {        
      UserModel.User hoster = await getUserModel(value.data()['hostID']);
      Lituation lit = Lituation.fromJson(value.data());
      if(!lit.observers.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({'observers': FieldValue.arrayUnion(u)}).then((value){
          dbRef.collection('users_lituations').doc(userID).update({"observedLituations": FieldValue.arrayUnion(l)});
        });
        if (hoster.deviceToken != "")
          sendPushNotification(hoster.deviceToken, "New Overserver", "${visitor.username} has is observing your ${lit.title}");
      }else{
        dbRef.collection('lituations').doc(lID).update({'observers': FieldValue.arrayRemove(u)}).then((value){
          dbRef.collection('users_lituations').doc(userID).update({"observedLituations": FieldValue.arrayRemove(l)});
        });
        if (hoster.deviceToken != "")
          sendPushNotification(hoster.deviceToken, "Quit Overserver", "${visitor.username} has quitted your ${lit.title}");
      }
    });
  }

  //adds user to lituation
  Future<void> approveUser(String userID , String lID){
    //TODO Send notification to approved user
    //Notification should say something "You have been approved for Lituation_name"
    var u = [userID];
    var l = [lID];
    dbRef.collection('lituations').doc(lID).get().then((value){
      Lituation lit = Lituation.fromJson(value.data());
      if(lit.pending.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({'pending': FieldValue.arrayRemove(u)}).then((value){
        dbRef.collection('lituations').doc(lID).update({'vibes': FieldValue.arrayUnion(u)}).then((value) {
          dbRef.collection('users_lituations').doc(userID).update({'pendingLituations': FieldValue.arrayRemove(l)}).then((value){
            dbRef.collection('users_lituations').doc(userID).update({'upcomingLituations': FieldValue.arrayUnion(l)}).then((value) async {
              //TODO send approval message
              UserModel.User user = await getUserModel(userID);              
              if (user.deviceToken != "")
                sendPushNotification(user.deviceToken, "Approved for lituation", "You have been approved for ${lit.title}");
            });
          });
        });
        });
      }
    });
  }

  //Removes a user from a Lituation (view usages in : viewLituation.dart)
  Future<void> removeUserFromLituation(String userID , String lID){
    //TODO Send Notification to removed user
    //notigication should say something like You have been removed from this Lituation.
    var u = [userID];
    var l = [lID];
    dbRef.collection('lituations').doc(lID).get().then((value){
      Lituation lit = Lituation.fromJson(value.data());
      if(lit.vibes.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({'vibes': FieldValue.arrayRemove(u)}).then((value){
            dbRef.collection('users_lituations').doc(userID).update({'pendingLituations': FieldValue.arrayRemove(l)}).then((value){
              dbRef.collection('users_lituations').doc(userID).update({'upcomingLituations': FieldValue.arrayRemove(l)}).then((value) async{
                //TODO send approval message
                UserModel.User user = await getUserModel(userID);              
                if (user.deviceToken != "")
                  sendPushNotification(user.deviceToken, "Removed for lituation", "You have been removed for ${lit.title}");
                });
            });
        });
      }
    });
  }

  //RSVP's user to a Lituation (view usages in : viewLituation.dart)
  Future<void> rsvpToLituation(String userID , String lID) async {
    //TODO Send Notification to lituation host
    //notification should say something like "user_x has rsvp'd for your lituation."
    var u = [userID];
    var l = [lID];
    //we add them to the list of pending vibes
    UserModel.User user = await getUserModel(userID);         
    dbRef.collection('lituations').doc(lID).get().then((value) async {
      Lituation lit = Lituation.fromJson(value.data());
      UserModel.User hoster = await getUserModel(lit.hostID);
    if(!lit.pending.contains(userID)){
      dbRef.collection('lituations').doc(lID).update({'pending': FieldValue.arrayUnion(u)}).then((value){
        dbRef.collection('users_lituations').doc(userID).update({"pendingLituations": FieldValue.arrayUnion(l)}).then((value){     
          if (hoster.deviceToken != "")
            sendPushNotification(hoster.deviceToken, "RSVP", "${user.username} has rsvp'd for your ${lit.title}");
        });
      });
    }else{
      dbRef.collection('lituations').doc(lID).update({'pending': FieldValue.arrayRemove(u)}).then((value){
        dbRef.collection('users_lituations').doc(userID).update({"pendingLituations": FieldValue.arrayRemove(l)}).then((value){     
          if (hoster.deviceToken != "")
            sendPushNotification(hoster.deviceToken, "RSVP", "${user.username} withdraw rsvp'd for your ${lit.title}");
        });
      });
    }
  });
  }

  Future<void> attendLituation(String userID , String lID) async{
    //TODO Send Notification to  lituation host
    //notification should say something like "New user on the guest list".
    var n = [userID];
    var l = [lID];
    dbRef.collection('lituations').doc(lID).get().then((value) async {
      Lituation lit = Lituation.fromJson(value.data());
      UserModel.User hoster = await getUserModel(lit.hostID);
      if(!lit.vibes.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({"vibes": FieldValue.arrayUnion(n)}).then((value){
          dbRef.collection('users_lituations').doc(userID).update({"upcomingLituations": FieldValue.arrayUnion(l)}).then((value){
            if (hoster.deviceToken != "")
              sendPushNotification(hoster.deviceToken, "New guest", "New User on the guest list");
          });
        });
      }else{
        dbRef.collection('lituations').doc(lID).update({"vibes": FieldValue.arrayRemove(n)}).then((value){
          dbRef.collection('users_lituations').doc(userID).update({"upcomingLituations": FieldValue.arrayRemove(l)}).then((value){
            if (hoster.deviceToken != "")
              sendPushNotification(hoster.deviceToken, "Remove guest", "User removed on the guest list");
          });
        });
      }
    });
  }

  //USER LITUATIONS FUNCTIONS
  Future<void> removeDraft(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"drafts": FieldValue.arrayRemove(data)});
  }
  Future<void> removeUserLituation(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"lituations": FieldValue.arrayRemove((data))});
  }
  Future<void> removePastLituation(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"pastLituations": FieldValue.arrayRemove((data))});
  }
  Future<void> removeUpcomingLituation(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"upcomingLituations": FieldValue.arrayRemove((data))});
  }
  Future<void> removeWatchedLituation(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"observedLituations": FieldValue.arrayRemove((data))});
  }
  Future<void> removePendingLituation(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"pendingLituations": FieldValue.arrayRemove((data))});
  }
  Future<void> removeInvitationLituation(String userId , String lID, String fromId) async {
    var data = ["${fromId}:${lID}"];
    var invites = [userId];
    await dbRef.collection('users_lituations').doc(userId).update({"invitations": FieldValue.arrayRemove(data)});
    await dbRef.collection('lituations').doc(lID).update({"invited": FieldValue.arrayRemove(invites)});
  }

  //DB lITUATION FUNCTIONS ----------------------------------------------
  //TODO move to Preview lituation
  Future<String> createLituation(Lituation l) async {
    //TODO Send notification to all invited users
    //Notification should say something like: "You have been invited to  lituation_x by host_name"

    List imgs = [];
    for(String path in l.thumbnailURLs){
     imgs.add(File(path));
    }
    l.thumbnailURLs.clear();
    String eventID = await postLituation(l);    
    UserModel.User hoster = await getUserModel(l.hostID);
    await uploadLituationMedia(l, imgs, hoster);
    await addToUserLituations(l.hostID, l.eventID);
    await addToUpcomingLituations(l.hostID, l.eventID);
    List<String> tokens = [];
    l.invited.forEach((element) async {      
      UserModel.User hoster = await getUserModel(element);
      if (hoster.deviceToken != "")
        tokens.add(hoster.deviceToken);
    });
    sendPushNotification("", "Invitation", "You have been invited to  ${l.title} by ${hoster.username}", tokens: tokens);
    return eventID;
  }
  Future <String> addToDrafts(Lituation l) async {
    List imgs = [];
    for(String path in l.thumbnailURLs){
      imgs.add(File(path));
    }
    l.thumbnailURLs.clear();    
    UserModel.User hoster = await getUserModel(l.hostID);
    String eventID = await postLituation(l);
    await uploadLituationMedia(l, imgs, hoster);
    await addToUserDrafts(l.hostID, l.eventID);
    return eventID;
  } 

  Future<String> postLituation(Lituation l) async {
    //dbRef.collection('lituations').doc().set(l.toJson());
    DocumentReference lRef = dbRef.collection("lituations").doc();
    l.eventID = lRef.id;
    await lRef.set(l.toJson());
    return l.eventID;
  }

  Future<List> uploadLituationMedia(Lituation l , List imgs, UserModel.User hoster) async{
    //TODO Send notification to host
    //Notification should say something like: "Your media for lituation_name have been succesfully uploaded!"

    List urls = [];
    for(var img in imgs){
      await upload(img, l).then((url){
       urls.add(url.ref.getDownloadURL().toString());
      }).catchError((err){
        return err;
      });
    }
    sendPushNotification(hoster.deviceToken, "Media upload", "Your media for ${l.title} have been succesfully uploaded!",);
    return urls;
  }
  Future<TaskSnapshot>  upload(File imageFile , Lituation l) async {
    String filename = DateTime.now().millisecondsSinceEpoch.toString();
    var imageData = await imageFile.readAsBytes();
    TaskSnapshot uploadTask = await dbMediaRef.ref().child('lituationThumbnails').child(l.hostID).child('lituations').child(l.eventID).child(filename).putData(imageData).then((value) async{
      await value.ref.getDownloadURL().then((url){
        dbRef.collection('lituations').doc(l.eventID).update({"thumbnail": FieldValue.arrayUnion([url.toString()])});
      });
      return value;
    });
    return uploadTask;
  }
  Future<void> createUserLituations(UserModel.UserLituations ul) async {
    dbRef.collection('users_lituations').doc(ul.userID).set(ul.toJson());
  }
  Future<void> addToUserDrafts(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"drafts": FieldValue.arrayUnion(data)});
  }
  Future<void> addToUserLituations(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"lituations": FieldValue.arrayUnion(data)});
  }
  Future<void> addToUpcomingLituations(String userId , String lID) async {
    var data = [lID];
    dbRef.collection('users_lituations').doc(userId).update({"upcomingLituations": FieldValue.arrayUnion(data)});
  }
  Future<void> addToUserInvitation(String userId , String lID, String fromId) async {
    var data = ["${fromId}:${lID}"];
    var invites = [userId];
    await dbRef.collection('users_lituations').doc(userId).update({"invitations": FieldValue.arrayUnion(data)});
    await dbRef.collection('lituations').doc(lID).update({"invited": FieldValue.arrayUnion(invites)});
  }

//VIBE Queries
  Future<void> acceptPendingVibe(String userID , String vibeID) async {
    //TODO Send notification to accepted user
    //Notification should say something like: "user_x has accepted your vibe request"

    var u = [vibeID];
    var m = [userID];
    cancelPendingVibeRequest(vibeID , userID).then((value) =>{
      dbRef.collection('vibing').doc(userID).update({'vibing': FieldValue.arrayUnion(u)}).then((value) async {
        dbRef.collection('vibed').doc(vibeID).update({'vibed': FieldValue.arrayUnion(m)});
        updateClout(userID, 5);
        UserModel.User user = await getUserModel(userID);
        UserModel.User vibe = await getUserModel(vibeID);
        sendPushNotification(vibe.deviceToken, "Accept Vibe", "${user.username} has accepted your vibe request",);        
      })
    });
  }

  //Removes a user's RSVP from 'pending' list in a Lituation (view usages in : viewLituation.dart)
  Future<void> cancelRSVP(String userID , String lID){
    //TODO Send notification to canceled user
    //Notification should say something like: "Your RSVP to lituation_x was denied."

    var u = [userID];
    var l = [lID];
    dbRef.collection('lituations').doc(lID).get().then((value){
      Lituation lit = Lituation.fromJson(value.data());
      if(lit.pending.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({'pending': FieldValue.arrayRemove(u)}).then((value){
          dbRef.collection('users_lituations').doc(userID).update({'pendingLituations': FieldValue.arrayRemove(l)}).then((value) async {
            //TODO send disapproval message
            UserModel.User user = await getUserModel(userID);
            sendPushNotification(user.deviceToken, "Deny RSVP", "Your RSVP to ${lit.title} was denided.",);
          });
        });
      }
    });
  }

  Future<void> removeVibed(String visitor , String visited) async{
    var u = [visitor];
    var v = [visited];
    dbRef.collection('vibed').doc(visitor).update({"vibed": FieldValue.arrayRemove(v)}).then((value){
      dbRef.collection('vibing').doc(visitor).update({"vibing": FieldValue.arrayRemove(u)}).then((value){
        return;
      });
    });
  }

  //unvibe
  Future<void> removeVibing(String visitor , String visited) async{
    var u = [visitor];
    var v = [visited];
    dbRef.collection('vibing').doc(visitor).update({"vibing": FieldValue.arrayRemove(v)}).then((value){
      dbRef.collection('vibed').doc(visitor).update({"vibed": FieldValue.arrayRemove(u)}).then((value){
        return;
      });
    });
  }

  //adds user to lituation
  Future<void> approveRSVP(String userID , String lID){
    //TODO Send notification to added user
    //Notification should say something like: "You have approved for and added to the guest list for lituation_x"
    var u = [userID];
    var l = [lID];
    dbRef.collection('lituations').doc(lID).get().then((value){
      Lituation lit = Lituation.fromJson(value.data());
      if(lit.pending.contains(userID)){
        dbRef.collection('lituations').doc(lID).update({'pending': FieldValue.arrayRemove(u)}).then((value){
          dbRef.collection('lituations').doc(lID).update({'vibes': FieldValue.arrayUnion(u)}).then((value) {
            dbRef.collection('users_lituations').doc(userID).update({'pendingLituations': FieldValue.arrayRemove(l)}).then((value){
              dbRef.collection('users_lituations').doc(userID).update({'upcomingLituations': FieldValue.arrayUnion(l)}).then((value) async{
                //TODO send approval message
                UserModel.User user = await getUserModel(userID);
                sendPushNotification(user.deviceToken, "Approve RSVP", "You have approved for and added to the guest list for ${lit.title}",);
              });
            });
          });
        });
      }
    });
  }

  Future<void> cancelPendingVibeRequest(String userID , String vibeID) async {
    var u = [vibeID];
    var m = [userID];
    dbRef.collection('vibing').doc(userID).update({"pendingVibing": FieldValue.arrayRemove(u)}).then((value){
      dbRef.collection('vibed').doc(vibeID).update({"pendingVibes": FieldValue.arrayRemove(m)});
      dbRef.collection('vibed').doc(userID).update({"pendingVibes": FieldValue.arrayRemove(u)}).then((value){
        dbRef.collection('vibing').doc(vibeID).update({"pendingVibing": FieldValue.arrayRemove(m)});
      });
    });
  }


  Future<void> completeRegistration(UserModel.User u) async {
    //TODO Send notification to new user
    //Notification should say something like: "Welcome To LIT!"

    String id = u.userID;
    await dbRef.collection('users').doc(id).set(u.toJson()).then((value){
      dbRef.collection(db_vibed_collection).doc(id).set(initNewUserVibed(id).toJson()).then((value){
        dbRef.collection(db_vibing_collection).doc(id).set(initNewUserVibing(id).toJson()).then((value){
          dbRef.collection(db_user_lituations_collection).doc(id).set(initNewUserLituations(id).toJson()).then((value){
            dbRef.collection(db_user_settings_collection).doc(id).set(initNewUserSettings(id).toJson()).then((value) {
              dbRef.collection(db_user_activity_collection).doc(id).set(initNewUserActivity(id).toJson()).then((value){
                return;
              });
            });
          });
        });
      });
    });
  }

  Future<void> resetSettingToDefault(String userID){
    dbRef.collection(db_user_settings_collection).doc(userID).set(initNewUserSettings(userID).toJson());
  }


  String handleAuthException(FirebaseAuthException e){
    print(e.code);
    switch(e.code){
      case "ERROR_INVALID_EMAIL":
        return auth_invalid_email_error_code;
        break;
      case "ERROR_WRONG_PASSWORD":
        return auth_wrong_password_error_code;
        break;
      case "ERROR_USER_NOT_FOUND":
        return auth_no_user_error_code;
        break;
      case "ERROR_USER_DISABLED":
        return auth_user_diabled_error_code;
        break;
      case "ERROR_TOO_MANY_REQUESTS":
        return auth_too_many_request_error_code;
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
        return auth_operation_not_allowed_error_code;
        break;
      case "ERROR_EMAIL_ALREADY_IN_USE":
        return auth_email_exists_error_code;
        break;
      default:
        return auth_operation_not_allowed_error_code;
    }
    }

    /*Register helper functions
    Help init user quickly with default*/

  UserModel.UserStatus initNewStatus(String userID){
    UserModel.UserStatus s = new  UserModel.UserStatus();
    s.user_id = userID;
    s.time = DateTime.now();
    s.status = 'Hello World';
    s.currentLocation = LatLng(0, 0);
    s.updateMessage = '';
    s.accumulatedClout = '';
    s.achievements = ['En-LIT-ened'];
    return s;
  }

  UserModel.UserActivity initNewUserActivity(String userID){
    UserModel.UserActivity ua = new  UserModel.UserActivity();
    ua.userID = userID;
    ua.interactedUsers = [];
    ua.likedPosts = [];
    ua.visitedLituations = [];
    ua.pendingVibes = [];
    return ua;
  }
  UserModel.UserLituations initNewUserLituations(String userID){
    UserModel.UserLituations u = new  UserModel.UserLituations();
    u.userID = userID;
    u.drafts = [];
    u.lituations = [];
    u.pastLituations = [];
    u.upcomingLituations = [];
    u.pendingLituations = [];
    u.observedLituations = [];
    u.recommendedLituations = [];
    u.invitations = [];
    return u;
  }
  Vibed initNewUserVibed(String userID){
    Vibed v = new Vibed();
    v.userID = userID;
    v.vibed = [];
    v.vibedCount = v.vibed.length.toString();
    v.pendingVibes = [];
    return v;
  }
  Vibing initNewUserVibing(String userID){
    Vibing v = new Vibing();
    v.userID = userID;
    v.vibing = [];
    v.vibingCount = v.vibing.length.toString();
    v.pendingVibing = [];
    return v;
  }
  UserModel.UserSettings initNewUserSettings(String userID){
    UserModel.UserSettings s = new  UserModel.UserSettings();
    s.userID = userID;
    s.vibe_visibility = PrivacySettings.PRIVATE;
    s.lituation_visibility = PrivacySettings.PRIVATE;
    s.activity_visibility = PrivacySettings.PRIVATE;
    s.location_visibility = PrivacySettings.PRIVATE;
    s.lituation_notifications = false;
    s.invitation_notifications = false;
    s.general_notifications = false;
    s.chat_notifications = false;
    s.vibe_notifications = false;
    s.adult_lituations = false;
    s.theme = "auto";
    return s;
  }

  Future<ChatRoomModel> getChatRoomModel(String roomID) async {
    var snapshot = await dbRef.collection('chat').doc(roomID).get();
    var data = snapshot.data();
    ChatRoomModel c = ChatRoomModel.fromJson(data);
    return c;
  }

  createChatRoom(ChatRoomModel chatroom) async {
    //TODO Send notifications to all users in room besides host/creator.
    //If the room has 2 users, the notification should say something like "user x starting a chat with you"
    //If the room has more than 2 users, the notification should say something like "you have been added to room_name"
    await dbRef.collection('chat').doc(chatroom.room_id).set(chatroom.toJson());
    UserModel.User creator = await getUserModel(chatroom.party[0]);
    for(int i = 1; i < chatroom.party.length; i ++) {
      String element = chatroom.party[i];
      UserModel.User p = await getUserModel(element); 
      if (chatroom.party.length == 2) {
        sendPushNotification(p.deviceToken, "Chat", "${creator.username} starting a chat with you");
      } else {
        sendPushNotification(p.deviceToken, "Chat", "You have been added to ${chatroom.room_name}");
      }
    }
  }

  sendMessageToRoom(String roomID , ChatMessage m) async {
    //TODO send notification to all users except sender in room who have notifications for chat enabled.
    await dbRef.collection('chat').doc(roomID).collection('messages').add(m.toJson());
    ChatRoomModel chatroom = await getChatRoomModel(roomID);
    for(int i = 0; i < chatroom.party.length; i ++) {
      String element = chatroom.party[i];
      if (m.user.uid == element)
        continue;
      UserModel.User p = await getUserModel(element); 
      sendPushNotification(p.deviceToken, "Chat", m.video != null ? "Sent a video" :  m.image != null ? "Sent a image" : m.text);
    };
  }

  getUserChatRooms(String userID) async {
    return await dbRef.collection('chat').where("party", arrayContains: userID).get();
  }

  Stream<DocumentSnapshot> getChatRoomParty(String roomID){
    return dbRef.collection('chat').doc(roomID).snapshots().where((event) => event.data().containsKey('party'));
  }

  Stream<QuerySnapshot> getMessages(String roomID){
    return dbRef.collection('chat').doc(roomID).collection('messages').orderBy('createdAt' , descending: false).snapshots();
  }
  }


