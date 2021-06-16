import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:loading_overlay/loading_overlay.dart';

class CustomWebView extends StatefulWidget {
  final String selectedUrl;

  CustomWebView({this.selectedUrl});

  @override
  _CustomWebViewState createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    flutterWebviewPlugin.onUrlChanged.listen((String url) {
      if (url.contains("#access_token")) {
        print("access_token");
        succeed(url);
      }

      if (url.contains(
          "https://www.facebook.com/connect/login_success.html?error=access_denied&error_code=200&error_description=Permissions+error&error_reason=user_denied")) {
        denied();
        print("access_token");
      }
    });

    flutterWebviewPlugin.onStateChanged.listen((event) {
      print("ddddddddddddddddddddddddddddddd");
    });

    flutterWebviewPlugin.onProgressChanged.listen((event) {
     if(event.toInt() == 1)
       {
         setState(() {
           _isLoading = false;
         });
       }
    });

  }

  denied() {
    Navigator.pop(context);
  }

  succeed(String url) {
    var params = url.split("access_token=");
    var endparam = params[1].split("&");
    Navigator.pop(context, endparam[0]);
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
          url: widget.selectedUrl,
          // initialChild: Container(
          //   alignment: Alignment.center,
          //     child:  Text(
          //       "Loading...",
          //       style: TextStyle(
          //           color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 25),
          //       textAlign: TextAlign.center,
          //     ),
          // ),
          appBar: new AppBar(
            backgroundColor: Color.fromRGBO(66, 103, 178, 1),
            title: new Text("Facebook login"),
          )
    );
  }
}
