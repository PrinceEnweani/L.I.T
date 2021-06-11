import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRViewer extends StatefulWidget {
  final Lituation lit;
  final String userID;

  const QRViewer({Key key, this.lit, this.userID}) : super(key: key);

  @override
  _QRViewerState createState() => _QRViewerState();
}

class _QRViewerState extends State<QRViewer> {
  static const double _topSectionTopPadding = 50.0;
  static const double _topSectionBottomPadding = 20.0;
  static const double _topSectionHeight = 50.0;
  GlobalKey globalKey = new GlobalKey();
  String _inputErrorText;
  final TextEditingController _textController =  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _contentWidget(context),
    );
  }
  _contentWidget(context) {
    String _dataString = "${QR_ID}:${widget.lit.eventID}:${widget.userID}";
    
    final bodyHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom;
    return  Container(
      color: const Color(0xFFFFFFFF),
      height: bodyHeight * 0.5 + 30,
      child:  Column(
        children: <Widget>[
          Center(
              child: RepaintBoundary(
                key: globalKey,
                child: QrImage(
                  data: _dataString,
                  size: 0.4 * bodyHeight,
                  errorStateBuilder: (cxt, err) {
                    return Container(
                      child: Center(
                        child: Text(
                          "Uh oh! Something went wrong...",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
           FlatButton(
              child:  Text("Close"),
              onPressed: () {
                setState((){
                  Navigator.pop(context);
                });
              },
            ),
        ],
      ),
    );
  }
}