import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/card_controller.dart';
import 'package:customer/controller/payment_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CreditCardSaveScreen extends StatelessWidget {
  const CreditCardSaveScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<CreditCardController>(
      init: CreditCardController(),
      builder: (controller) {
        return GestureDetector(
          onTap: (){
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title:  Text("Cadastrar Cartão".tr),
              leading: InkWell(
                  onTap: () {
                    Get.back();
                    Get.find<PaymentController>().fetchCustomerCards();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  )),
            ),
            body: controller.isLoading.value
                ? Constant.loader()
                : Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
              child: Column(
                children: [
                  Container(
                    child: CreditCardWidget(
                      cardNumber: controller.cardNumber.value,
                      expiryDate: controller.expiryDate.value,
                      cardHolderName: controller.cardHolderName.value,
                      cvvCode: controller.cvvCode.value,
                      isHolderNameVisible: true,
                      obscureCardNumber: controller.isUpdated.value,
                      obscureInitialCardNumber: controller.isUpdated.value,
                      cardBgColor: Colors.teal,
                      labelCardHolder: 'Nome Cartão',
                      labelValidThru: 'Val.',
                      showBackView: false, //true when you want to show cvv(back) view
                      onCreditCardWidgetChange: (CreditCardBrand brand) {}, // Callback for anytime credit card brand is changed
                    ),
                  ),
                  controller.isUpdated.value ? Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 0),
                      child: ButtonThem.buildButton(
                        context,
                        title: "Adicionar Cartão".tr,
                        onPress: () async {
                          await controller.sendCreditCardToSave(themeChange, context);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ) :
                  Expanded(
                    child: Container(
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            CreditCardForm(
                              formKey: controller.formKey,
                              obscureCvv: true,
                              obscureNumber: false,
                              cardNumber: controller.cardNumber.value,
                              cvvCode: controller.cvvCode.value,
                              isHolderNameVisible: true,
                              isCardNumberVisible: true,
                              isExpiryDateVisible: true,
                              cardHolderName: controller.cardHolderName.value,
                              expiryDate: controller.expiryDate.value,
                              inputConfiguration: const InputConfiguration(
                                cardNumberDecoration: InputDecoration(
                                  labelText: 'Número do Cartão',
                                  hintText: 'XXXX XXXX XXXX XXXX',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                                expiryDateDecoration: InputDecoration(
                                  labelText: 'Validade',
                                  hintText: 'XX/XX',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                                cvvCodeDecoration: InputDecoration(
                                  labelText: 'CVV',
                                  hintText: 'XXX',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                                cardHolderDecoration: InputDecoration(
                                  labelText: 'Nome no Cartão',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                              ), onCreditCardModelChange: controller.onCreditCardModelChange,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15, right: 20, top: 20, bottom: 0),
                              child: DropdownButtonFormField<String>(
                                value: controller.cardType.value,
                                items: ['Crédito', 'Débito']
                                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                    .toList(),
                                onChanged: (value) {
                                  controller.cardType.value = value!;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Tipo do Cartão',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 0),
                              child: DropdownButtonFormField<String>(
                                value: controller.tipoDocumento.value,
                                items: ['CPF', 'CNPJ'].map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  controller.tipoDocumento.value = value!;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Tipo Documento',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 0),
                              child: TextField(
                                controller: controller.cpfController,
                                decoration: InputDecoration(
                                  labelText: 'CPF/CNPJ',
                                  border: OutlineInputBorder(),
                                  hintText: controller.tipoDocumento.value == 'CPF'? '000.000.000-00' : '00.000.000/0000-00',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                                inputFormatters: [controller.tipoDocumento.value == 'CPF' ? controller.cpfMaskFormatter: controller.cnpjMaskFormatter],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 0),
                              child: TextField(
                                controller: controller.apelidoController,
                                decoration: InputDecoration(
                                  labelText: 'Apelido Cartão',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                ),
                                keyboardType: TextInputType.name,
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(left: 15, right: 20, top: 30, bottom: 0),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: "Adicionar Cartão".tr,
                                  onPress: () async {
                                    ShowToastDialog.showLoader("Aguarde...".tr);
                                    await controller.sendCreditCardToSave(themeChange, context);
                                    ShowToastDialog.closeLoader();

                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 50,)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
