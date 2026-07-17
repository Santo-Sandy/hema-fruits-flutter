import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

class CashfreeService {
  final _gateway = CFPaymentGatewayService();

  void init({
    required Function(String orderId) onSuccess,
    required Function(CFErrorResponse error, String orderId) onError,
  }) {
    _gateway.setCallback(onSuccess, onError);
  }

  Future<dynamic> pay({
    required String orderId,
    required String paymentSessionId,
    bool sandbox = true,
  }) async {
    try {
      final session = CFSessionBuilder()
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .setEnvironment(
            sandbox ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION,
          )
          .build();

      final checkout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _gateway.doPayment(checkout);
      return "";
    } on CFException catch (e) {
      debugPrint("Message: ${e.message}");
      debugPrint("Code: ${e}");
      return "";
    } catch (e) {
      print(e);
      return "";
    }
  }
}
