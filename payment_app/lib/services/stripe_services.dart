import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';


class  StripeServices {

  static const Map<String, String> _testTokens= {

    '1111111122222222' : 'tok_visa',
    '3333333344444444' : 'tok_visa_debit',
    '5555555566666666' : 'tok_mastercard',
    '7777777788888888' : 'tok_mastercard_debit',
    '9999999900000000' : 'tok_chargeDeclined',
    '1010101010101010' : 'tok_chargeDeclineInsufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];


    if (token == null) {
      return <String, dynamic> {
        'sucess' : false,
        'error' : 'unknown test card'
      };
    }

    try{

      final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
          headers: <String, String> {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content_Type': 'application/x-www-form-urlencoded',
          },
          body: <String, String>{
            'amount' : amountInCentavos,
            'currency' : 'php',
            'payment_method_types[]': 'card',
            'payment_method_day[type]': 'card',
            'payment_method_data[card][token]': token,
            'confirm': 'true',
          }
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeded') {
        final paidAmount = (data['amount'] as num) / 100;
        return <String, dynamic> {
          'success' : true,
          'id': data['id'].toString(),
          'amount': paidAmount,
          'state': data ['status'].toString(),
        };
      }else {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map)['message']?.toString() ?? 'payment failed'
            : 'payment failed';
        return <String, dynamic> {
          'success' : false,
          'error' : errorMsg,
        };
      }

    }catch (e) {
      return<String, dynamic> {
        'success' :false,
        'error' : e.toString(),
      };
    }
  }
}