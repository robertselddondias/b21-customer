// import 'dart:convert';
//
// import 'package:customer/constant/constant.dart';
// import 'package:customer/model/credit_card_model.dart';
// import 'package:customer/utils/Preferences.dart';
// import 'package:customer/utils/fire_store_utils.dart';
// import 'package:http/http.dart' as http;
//
// class MercadoPagoService {
//
//   final String accessToken;
//
//   MercadoPagoService({required this.accessToken});
//
//   Future<Map<String, dynamic>?> buscarClientePorEmail(String email) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/search?email=$email');
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     };
//     final response = await http.get(url, headers: headers);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['results'].isNotEmpty) {
//         return data['results'][0];
//       }
//     }
//     return null;
//   }
//
//   Future<Map<String, dynamic>> criarCliente(String email, String nome) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers');
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     };
//
//     final body = jsonEncode({
//       'email': email,
//       'first_name': nome,
//     });
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 201) {
//       final data = jsonDecode(response.body);
//       return data;  // ID do novo cliente criado é retornado aqui
//     } else {
//       throw Exception('Erro ao criar cliente: ${response.body}');
//     }
//   }
//
//   Future<Map<String, dynamic>> atualizarCliente(String customerId, String nome) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/$customerId');
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     };
//
//     final body = jsonEncode({
//       'first_name': nome,
//     });
//
//     final response = await http.put(url, headers: headers, body: body);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data;
//     } else {
//       throw Exception('Erro ao atualizar cliente: ${response.body}');
//     }
//   }
//
//   Future<String> obterOuCriarCliente(String email, String nome) async {
//     final clienteExistente = await buscarClientePorEmail(email);
//
//     if (clienteExistente != null) {
//       return clienteExistente['id'];
//     } else {
//       final novoCliente = await criarCliente(email, nome);
//       return novoCliente['id'];
//     }
//   }
//
//   // Método para consultar as informações do payer/customer
//   Future<Map> consultarCustomer(String customerId) async {
//     final url = Uri.parse("https://api.mercadopago.com/v1/customers/$customerId");
//
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     };
//
//     final response = await http.get(url, headers: headers);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data;
//     } else {
//       print('Erro ao consultar Customer: ${response.statusCode} - ${response.body}');
//       throw Exception('Erro ao pesquisar o customer');
//     }
//   }
//
//
//   // Método para gerar um token de cartão (API v2)
//   Future<String> createCardToken({
//     required String cardNumber,
//     required String expirationMonth,
//     required String expirationYear,
//     required String cvv,
//     required String cardHolderName,
//     required String identificationType,
//     required String identificationNumber,
//     required String cardName
//   }) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/card_tokens');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'card_number': cardNumber,
//           'expiration_month': expirationMonth,
//           'expiration_year': expirationYear,
//           'security_code': cvv,
//           'cardholder': {
//             'name': cardHolderName,
//             'identification': {
//               'type': identificationType,
//               'number': identificationNumber,
//             },
//           },
//         }),
//       );
//
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final responseCardToken = jsonDecode(response.body);
//
//         var responseCustomerCard = await saveCardForCustomer(
//             customerId: Preferences.getString("customerId"),
//             cardToken: responseCardToken['id']);
//
//         CreditCardUserModel creditCardModel = CreditCardUserModel();
//         creditCardModel.expirationYear = responseCustomerCard["expiration_year"];
//         creditCardModel.expirationMonth = responseCustomerCard['expiration_month'];
//         creditCardModel.brandType = responseCustomerCard['payment_method']['name'];
//         creditCardModel.transationalType = responseCustomerCard['payment_method']['payment_type_id'];
//         creditCardModel.creditCardToken = responseCardToken['id'];
//         creditCardModel.lastFourDigits = responseCustomerCard['last_four_digits'];
//         creditCardModel.customerId = Preferences.getString("customerId");
//         creditCardModel.cardHolderName = cardName;
//         creditCardModel.urlFlag = responseCustomerCard['payment_method']['thumbnail'];
//         creditCardModel.userId = FireStoreUtils.getCurrentUid();
//         creditCardModel.cardId = responseCustomerCard['id'];
//         creditCardModel.id = Constant.getUuid();
//         creditCardModel.tipoDocumento = identificationType;
//         creditCardModel.numeroDocumento = identificationNumber;
//         creditCardModel.flagCard = responseCustomerCard['payment_method']['name'];
//         creditCardModel.cvv = cvv;
//
//
//         await FireStoreUtils.setCreditCard(creditCardModel);
//
//         return responseCustomerCard['id'];
//       } else {
//         throw Exception('Erro ao criar token do cartão: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Erro ao criar token do cartão: $e');
//     }
//   }
//
//   // Método para associar um cartão ao cliente usando o token do cartão (API v2)
//   Future<Map<String, dynamic>> saveCardForCustomer({
//     required String customerId,
//     required String cardToken}) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/$customerId/cards');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'token': cardToken
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Erro ao salvar o cartão: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Erro ao salvar o cartão: $e');
//     }
//   }
//
//   // Método para listar os cartões do cliente
//   Future<List<dynamic>> listCustomerCards(String customerId) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/$customerId/cards');
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Erro ao listar cartões do cliente: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Erro ao listar cartões do cliente: $e');
//     }
//   }
//
//   // Novo método: obter um cartão específico pelo customerId e cardId
//   Future<Map<String, dynamic>> getCardById({
//     required String customerId,
//     required String cardId,
//   }) async {
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/$customerId/cards/$cardId');
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Erro ao obter cartão: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Erro ao obter cartão: $e');
//     }
//   }
//
//   // Função para realizar uma transação com verificação de token
//   Future<bool> realizarTransacaoComVerificacao(CreditCardUserModel card, int amount) async {
//     try {
//       await realizarTransacao(card,amount);
//     } catch (e) {
//       if (e.toString().contains("Invalid card_token_id")) {
//         print("Token expirado. Gerando novo token...");
//         final novoToken = await gerarNovoToken(card.creditCardToken!, card.cvv!);
//         await realizarTransacao(card, amount);
//         return true;
//       } else {
//         print("Erro na transação: $e");
//         return false;
//       }
//     }
//     return false;
//   }
//
//   // Função para realizar a transação
//   Future<void> realizarTransacao(CreditCardUserModel card, int amount) async {
//     final url = Uri.parse("https://api.mercadopago.com/v1/payments");
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//       'X-Idempotency-Key': Constant.getUuid()
//     };
//
//     var customer = await consultarCustomer(card.customerId!);
//
//
//     final body = jsonEncode({
//       "transaction_amount": amount,
//       "token": card.creditCardToken!,
//       "payment_method_id": card.brandType,
//       "installments": 1,
//       "payer": {
//         "email": customer['email'],
//         "identification": {
//           "type": card.tipoDocumento,
//           "number": card.numeroDocumento
//         }
//       },
//     });
//
//     // Envia a requisição para realizar a transação
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 200 || response.statusCode == 201 ) {
//       print('Transação realizada com sucesso: ${response.body}');
//       // } //else {
//       //   final errorData = jsonDecode(response.body);
//       //   throw Exception(errorData['message']);
//       // }
//     }
//   }
//
//   // Função para gerar um novo token caso o atual esteja expirado
//   Future<String> gerarNovoToken(String cardId, String securityCode) async {
//     final url = Uri.parse("https://api.mercadopago.com/v1/card_tokens");
//     final headers = {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     };
//
//     // Corpo da requisição para gerar novo token
//     final body = jsonEncode({
//       "card_id": cardId,
//       "security_code": securityCode,
//     });
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 201) {
//       final data = jsonDecode(response.body);
//       return data['id'];  // Retorna o novo card token
//     } else {
//       throw Exception('Erro ao gerar novo token: ${response.body}');
//     }
//   }
//
//   Future<Map<String, dynamic>> realizarPagamentoComCardToken({
//     required String token,
//     required String customerId,
//     required String cardId,
//     required double valor,
//     required String descricao,
//     required int parcelas,
//     required String paymentMethodId,
//     required String emailComprador,
//     required String tipoDocumento,
//     required String numeroDocumento,
//   }) async {
//     final url = Uri.parse("https://api.mercadopago.com/v1/payments");
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $accessToken'
//     };
//
//     var responseTokenCardUpdate = await atualizarTokenCartao(cardId: token);
//     var responseTokenCard = await saveCardForCustomer(customerId: customerId, cardToken: responseTokenCardUpdate['id']);
//
//     final body = jsonEncode({
//       "transaction_amount": 100.0,
//       "token": token, // Aqui você usa o card token gerado
//       "description": descricao,
//       "installments": parcelas,
//       "payment_method_id": paymentMethodId,
//       "payer": {
//         "email": emailComprador,
//         "identification": {
//           "type": tipoDocumento,
//           "number": numeroDocumento,
//         }
//       }
//     });
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       var transacaoResponse = jsonDecode(response.body);
//       if(transacaoResponse['status'] == 'approved') {
//         print('');
//       }
//
//       return jsonDecode(response.body); // Sucesso: pagamento realizado
//     } else {
//       throw Exception("Erro no pagamento: ${response.body}");
//     }
//   }
//
//   Future<Map<String, dynamic>> atualizarTokenCartao({
//     required String cardId,  // ID do cartão já salvo
//   }) async {
//     final url = Uri.parse("https://api.mercadopago.com/v1/card_tokens");
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $accessToken',  // Substitua com seu access token
//     };
//
//     final body = jsonEncode({
//       "card_token": cardId,  // Usando o ID do cartão já salvo para gerar um novo token
//     });
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       // Retorna o novo token gerado
//       return jsonDecode(response.body);
//     } else {
//       throw Exception("Erro ao renovar token: ${response.body}");
//     }
//   }
//
//   Future<bool> deleteCard(String cardId) async {
//     var customerId = Preferences.getString('customerId');
//     final url = Uri.parse('https://api.mercadopago.com/v1/customers/$customerId/cards/$cardId');
//
//     try {
//       final response = await http.delete(
//         url,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         print("Cartão excluído com sucesso.");
//         return true;
//       } else {
//         print("Falha ao excluir o cartão. Código: ${response.statusCode}");
//         print("Resposta: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       print("Erro ao excluir o cartão: $e");
//       return false;
//     }
//   }
// }
