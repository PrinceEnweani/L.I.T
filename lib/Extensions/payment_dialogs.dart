
import 'package:flutter/material.dart';

class PaymentFailedDialog extends StatefulWidget {
  PaymentFailedDialog({Key key}) : super(key: key);

  @override
  PaymentFailedDialogState createState() => new PaymentFailedDialogState();
}

class PaymentFailedDialogState extends State<PaymentFailedDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 200,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          color: Colors.white,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Wrap(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                color: Colors.red[300],
                child: Column(
                  children: <Widget>[
                    Container(height: 10),
                    Icon(Icons.credit_card, color: Colors.white, size: 80),
                    Container(height: 10),
                    Text("Payment Failed",
                        style: TextStyle(color: Colors.white)),
                    Container(height: 10),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Text("Please check your card balance again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    Container(height: 10),
                    FlatButton(
                      padding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(18.0)),
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.red[300],
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessDialog extends StatefulWidget {
  PaymentSuccessDialog({Key key}) : super(key: key);

  @override
  PaymentSuccessDialogState createState() => new PaymentSuccessDialogState();
}

class PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 200,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          color: Colors.white,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Wrap(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                color: Colors.lightGreen[400],
                child: Column(
                  children: <Widget>[
                    Container(height: 10),
                    Icon(Icons.verified_user, color: Colors.white, size: 80),
                    Container(height: 10),
                    Text("Payment Successful",
                        style: TextStyle(color: Colors.white)),
                    Container(height: 10),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Text(
                        "Thank you for participate. Your account has been charged and your transaction is successful. You can attend the lituation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    Container(height: 10),
                    FlatButton(
                      padding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(18.0)),
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.lightGreen[500],
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
