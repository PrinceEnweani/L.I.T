

import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';

class VibeProvider {

  Auth db = Auth();
  final String userID;

  VibeProvider(this.userID);

  vibingStream(){
    return db.getVibing(userID);
  }
  lituationStream(String lID){
    return db.getLituationByID(lID);
  }
  vibedStream(){
    return db.getVibed(userID);
  }
  friendsStream(){
    return db.getVibedAndVibing(userID).asStream();
  }
  sendInvitation(String recipientID , String message , String lID){
    Invitation i = Invitation();
    i.lituationID = lID;
    i.senderID = userID;
    i.recipient = recipientID;
    i.message = message;
    i.senderID = userID;
    i.invitationID = userID + ":" + lID + ":" + recipientID;
    i.dateSent = DateTime.now();
    db.sendInvite(i);
  }

  userStream(){
    return db.getUser(userID);
  }

  cancelVibed(String id){
    return db.removeVibed(userID, id);
  }
  cancelVibing(String id){
    return db.removeVibing(userID, id);
  }
  cancelVibeRequest(String id){
    return db.cancelPendingVibeRequest(userID, id);
  }

  acceptVibe(String id){
    return db.acceptPendingVibe(userID, id);
  }
  sendVibeRequest(String visitor ,  String userID){
    db.sendVibeRequest(visitor, userID);
  }
  getUserStreamByID(String id){
    return db.getUser(id);
  }

}