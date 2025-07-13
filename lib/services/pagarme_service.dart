import 'dart:convert';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/credit_card_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PagarMeService {
  final String _API_KEY = 'sk_test_0ac67f54dbe540848a4c73a12d9a1dd3';

  /// Base URL da API do Pagar.me
  static const String baseUrl = 'https://api.pagar.me/core/v5';

  /// Gera o cabeçalho de autenticação com Basic Authentication
  Map<String, String> _getAuthHeaders() {
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$_API_KEY:'))}';
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  /// Cadastra um cartão de crédito ou débito no Pagar.me
  Future<String> createCard({
    required String cardNumber,
    required String cardHolderName,
    required String cardExpirationDate,
    required String cardCvv,
    required String alias,
    required String documentNumber,
    String? documentType
  }) async {
    await createOrUpdateCustomer(documentType, documentNumber);

    final url = Uri.parse('$baseUrl/customers/${Preferences.getString("customerId")}/cards');
    final dateSplit = cardExpirationDate.split('/');
    final body = {
      "number": cardNumber,
      "holder_name": cardHolderName,
      "exp_year": dateSplit[1],
      "exp_month": dateSplit[0],
      "cvv": cardCvv,
    };

    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseSaveCard = jsonDecode(response.body);
        CreditCardUserModel creditCardModel = CreditCardUserModel();
        creditCardModel.cardId = responseSaveCard['id'];
        creditCardModel.lastFourDigits = responseSaveCard['last_four_digits'];
        creditCardModel.brandType = responseSaveCard['brand'];
        creditCardModel.cardHolderName = responseSaveCard['holder_name'];
        creditCardModel.expirationYear = responseSaveCard["exp_year"];
        creditCardModel.expirationMonth = responseSaveCard['exp_month'];
        creditCardModel.transationalType = responseSaveCard['type'];
        creditCardModel.customerId = responseSaveCard['customer']['id'];
        creditCardModel.numeroDocumento = documentNumber.replaceAll('.', '').replaceAll('-', '');
        creditCardModel.tipoDocumento = documentType;
        creditCardModel.userId = FireStoreUtils.getCurrentUid();
        creditCardModel.id = Constant.getUuid();

        creditCardModel.cardAliasName = alias;

        await FireStoreUtils.setCreditCard(creditCardModel);
        return responseSaveCard['id'];
      } else {
        throw Exception(
          'Erro ao criar cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  Future<void> createOrUpdateCustomer(String? documentType, String documentNumber) async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
        if (value != null) {
          UserModel userModel = UserModel();
          userModel = value;

          if(userModel.customerId == null) {
            final customerId = await createCustomer(
                name: userModel.fullName!,
                email: userModel.email!,
                documentType: documentType!,
                documentNumber: documentNumber,
                phone: userModel.phoneNumber!
            );
            userModel.customerId = customerId;
            FireStoreUtils.updateUser(userModel);
            Preferences.setString("customerId", customerId);
          } else {
            Preferences.setString("customerId", userModel.customerId!);
            var response = await getCustomerDetails(userModel.customerId!);
            await updateCustomer(
                customerId: userModel.customerId!,
                name: userModel.fullName!,
                email: userModel.email!,
                documentType: documentType! == '' ? response['documentType'] : documentType,
                documentNumber: documentNumber == '' ? response['documentNumber'] : documentNumber,
                phone: userModel.phoneNumber
            );
          }
        }
      });
    }
  }

  /// Obtém os detalhes de um cartão pelo ID
  Future<Map<String, dynamic>> getCardDetails(String cardId) async {
    final url = Uri.parse('$baseUrl/cards/$cardId');

    try {
      final response = await http.get(
        url,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao buscar detalhes do cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Remove um cartão pelo ID
  Future<void> deleteCard(String cardId) async {
    final url = Uri.parse('$baseUrl/cards/$cardId');

    try {
      final response = await http.delete(
        url,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Erro ao deletar o cartão: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cadastra um cliente no Pagar.me
  Future<String> createCustomer({
    required String name,
    required String email,
    required String documentNumber,
    required String documentType,
    required String phone
  }) async {
    final url = Uri.parse('$baseUrl/customers');

    final body = {
      "name": name,
      "email": email,
      "document": documentNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      "documentType": documentType,
      "code": FireStoreUtils.getCurrentUid(),
      "type": documentType == 'CPF' ? 'individual' : 'company',
      "phone": phone
    };

    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['id'];
      } else {
        throw Exception(
          'Erro ao criar cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Obtém os detalhes de um cliente pelo ID
  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    try {
      final response = await http.get(
        url,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao buscar detalhes do cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Atualiza os dados de um cliente
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    String? name,
    String? email,
    String? documentNumber,
    String? documentType,
    String? phone
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    final body = {
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (documentNumber != null) "document": documentNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      if (documentType != null) "document_type": documentType,
      "type": documentType == 'CPF' ? 'individual' : 'company',
      "code": FireStoreUtils.getCurrentUid()
    };

    try {
      final response = await http.put(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erro ao atualizar cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cria um pedido na API do Pagar.me
  Future<http.Response> createOrder(
      {
        required CreditCardUserModel creditCard,
        required int amount,
        required String orderId
      }
      ) async {
    final url = Uri.parse('$baseUrl/orders');


    final body = {
      "customer_id": creditCard.customerId,
      "code": orderId,
      "items": [
        {
          'amount': amount,
          'description': 'Viagem customerId: ${creditCard.customerId} - UsuarioId: ${creditCard.userId}',
          'quantity': 1,
          'code': 1
        },
      ],
      "payments": [{
        'credit_card':{
          'card_id': creditCard.cardId
        },
        'amount': amount,
        'payment_method': 'credit_card'
      }]
    };

    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception(
          'Erro ao criar pedido: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o Pagar.me: $e');
    }
  }

  /// Cria uma transação Pix
  Future<http.Response> createPixTransaction({
    required int amount,
    required String orderId
  }) async {

    await createOrUpdateCustomer('', '');

    final url = Uri.parse("$baseUrl/orders");

    final body = {
      "items": [
        {
          "amount": amount,
          "quantity": 1,
          "code": "pix_payment",
          "description": "Pagamento via Pix"
        }
      ],
      "customer_id": Preferences.getString('customerId'),
      "code": orderId,
      "payments": [
        {
          "payment_method": "pix",
          "pix": {
            "expires_in": '360'
          }
        }
      ]
    };

    final response = await http.post(url, headers: _getAuthHeaders(), body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    } else {
      throw Exception("Erro ao criar transação Pix: ${response.body}");
    }
  }
}
