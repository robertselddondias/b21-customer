import 'package:customer/constant/constant.dart';
import 'package:customer/controller/payment_controller.dart';
import 'package:customer/model/credit_card_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CardListPage extends StatelessWidget {
  const CardListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PaymentController>(
      init: PaymentController(),
      builder: (controller) {
        return Scaffold(// Cor de fundo leve
          backgroundColor: AppColors.primary,
          body: controller.isLoading.value
              ? Constant.loader()
              : Column(
            children: [
              Expanded(

                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
                  child: controller.customerCards.isNotEmpty
                      ? ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: controller.customerCards.length,
                    itemBuilder: (context, index) {
                      CreditCardUserModel card = controller.customerCards[index];
                      String imageCard = '';

                      if(card.brandType == 'Mastercard') {
                        imageCard = 'mastercard.png';
                      } else if(card.brandType == 'Visa') {
                        imageCard = 'visa.png';
                      }
                      return Obx(() {
                        bool isSelected = controller.creditCardSelection.value == card;

                        return Dismissible(
                          key: Key(card.id!), // Use um identificador único para o cartão
                          direction: DismissDirection.endToStart, // Swipe da direita para a esquerda
                          confirmDismiss: (direction) async {
                            // Mostra a caixa de diálogo de confirmação antes de excluir
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirmar Exclusão"),
                                  content: Text("Você realmente deseja excluir este cartão?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false), // Cancela a exclusão
                                      child: Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true), // Confirma a exclusão
                                      child: Text(
                                        "Excluir",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                            return confirmDelete; // Retorna true para confirmar o swipe, false para cancelar
                          },
                          onDismissed: (direction) async {
                            // Remove o cartão após a confirmação
                            await controller.removeCustomerCard(card, context); // Método para remover o cartão do controlador
                          },
                          background: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300), // Animação suave ao selecionar
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.lightBlue[50] : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!, // Borda fina cinza
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: Offset(0, 5),
                                  ),
                                ]
                                    : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/$imageCard',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.cardHolderName ?? 'Nome do Cartão',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '**** **** **** ${card.lastFourDigits ?? ''}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Val: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '${card.expirationMonth ?? ''}/${card.expirationYear ?? ''}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                      });
                    },
                  )
                      : Center(
                    child: Text(
                      "Nenhum cartão disponível",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),

                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
