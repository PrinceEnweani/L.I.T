import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:stripe_payment/stripe_payment.dart';

//This whole class is shitty
//ToDo: Looking at this whole thing is shitty, I didn't really understand how the whole thing worked until it was too late. I guess i am fucked then

class PaymentService {
  String _publishableKey =
      stripe_public_key; // t this yourself, e.g using curl

  final HttpsCallable INTENT = FirebaseFunctions.instance
      .httpsCallable('createPaymentIntent');

  final HttpsCallable INTENT1 = FirebaseFunctions.instance
      .httpsCallable('chargeExistingCustomer');

  final HttpsCallable INTENT2 = FirebaseFunctions.instance
      .httpsCallable('deleteCustomer');

  final HttpsCallable INTENT3 = FirebaseFunctions.instance
      .httpsCallable('createCustomerWithoutCharge');

  int paymentAmount;
  String customerId;
  String cardToken;
  //I really don't like adding context's to services and maybe i'll fix it in the future but i need the user to compulsory restart the app
  BuildContext context;

  PaymentService.pay(this.paymentAmount, this.context, Function afterPayment) {
    createCardandPay().then((res) {
      afterPayment(res);
    });
  }

  PaymentService.saveCard() {
    createAndSaveCard();
  }

  PaymentService.payAsExistingCustomer(
      this.customerId, this.paymentAmount, this.context) {
    payAsExistingCustomer();
  }

  PaymentService.deleteCustomer(this.customerId, this.cardToken) {
    deleteCustomer();
  }

  void setError(dynamic error) {
//    Fluttertoast.showToast(msg: error.toString());
    print(error.toString());
  }

  void finalizePayment() {
    Alert(
        context: context,
        style: AlertStyle(isCloseButton: false, isOverlayTapDismiss: false),
        title: "Success",
        desc: "Payment Successful",
        buttons: [
          DialogButton(
            child: Text("Done"),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            color: Colors.green,
          )
        ]).show();
    //When the payment is made and everything has been processed you want to make the user close the app by force
  }

  createAndSaveCard() async {
    try {
      StripePayment.setOptions(StripeOptions(
          publishableKey: _publishableKey,
          merchantId: "Test",
          androidPayMode: 'test'));
      bool canNativePay = await StripePayment.canMakeNativePayPayments(
          ["visa", "master_card", "american_express"]);

      if (canNativePay) {
        var paymentToken = await StripePayment.paymentRequestWithNativePay(
          androidPayOptions: AndroidPayPaymentRequest(
            totalPrice: paymentAmount.toString(),
            currencyCode: "USD",
          ),
          applePayOptions: ApplePayPaymentOptions(
            countryCode: 'USA',
            currencyCode: 'USD',
            items: [
              ApplePayItem(
                label: 'Quizzer Subscription',
                amount: paymentAmount.toString(),
              )
            ],
          ),
        ).catchError(setError);
        paymentToken.card.toJson();
        print(paymentToken?.card?.token);
      } else {
        var paymentMethod = await StripePayment.paymentRequestWithCardForm(
            CardFormPaymentRequest());
        print(paymentMethod?.card?.token);
        if (paymentMethod != null) {
          var response = await INTENT3
              .call(<String, dynamic>{'payment_method': paymentMethod.id});
          print(response.data);
        }
      }
    } catch (er) {
      setError(er);
      return false;
    }
  }

  payAsExistingCustomer() async {
    try {
      StripePayment.setOptions(StripeOptions(
          publishableKey: _publishableKey,
          merchantId: "Test",
          androidPayMode: 'test'));

      var response = await INTENT1.call(<String, dynamic>{
        'amount': paymentAmount * 100,
        'currency': 'usd',
        "customer_id": customerId
      });
      print(response.data);
      if (response.data != "no_payment_method") {
        await StripePayment.confirmPaymentIntent(PaymentIntent(
            clientSecret: response.data["client_secret"],
            paymentMethodId: response.data['payment_method']));
      } else {
        Fluttertoast.showToast(msg: "Payment Failed, Try again");
        //If the payment fails you want to clear out the customer and restart by logging a new card
        //I could start trying to add a new payment method to the customer. But that would be more stress and this is better
        var response =
            await INTENT2.call(<String, dynamic>{"customer_id": customerId});
        if (response.data == true) {
        } else {
          Fluttertoast.showToast(msg: "Fatal Error Occured");
        }
      }
    } catch (er) {
      print(er);
      setError(er);
      return false;
    }
  }

  deleteCustomer() async {
    try {
      if (customerId == null) return;
      var response =
          await INTENT2.call(<String, dynamic>{"customer_id": customerId});
      if (response.data == true) {
        //Handle payment
      } else {
        Fluttertoast.showToast(msg: "Fatal Error Occured");
      }
    } catch (er) {
      print(er);
      setError(er);
    }
  }

  Future<bool> createCardandPay() async {
    try {
      StripePayment.setOptions(StripeOptions(
          publishableKey: _publishableKey,
          merchantId: "Test",
          androidPayMode: 'test'));

      //ToDo: The whole native pay thing is really confusing and i can't figure out how to create a stripe customer from the native google and apple pay Id
      //For now i will have to collect customer details manually

      var paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());
      /*var response = await INTENT.call(<String, dynamic>{
        'amount': paymentAmount * 100,
        'currency': 'usd',
        'payment_method': paymentMethod.id
      });*/
      var response = await getStripeIntent(paymentMethod.id, "${paymentAmount * 100}", "usd");
      var data = jsonDecode(response);
      await StripePayment.confirmPaymentIntent(PaymentIntent(
        clientSecret: data["client_secret"],
        paymentMethodId: paymentMethod.id,
      ));
      print("Processing Payment");
      return true;
    } catch (er) {
      print(er);
      setError(er);
      return false;
    }
  }
}
