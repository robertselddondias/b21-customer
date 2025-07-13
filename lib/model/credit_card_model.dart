class CreditCardUserModel {

  String? id;
  String? cardHolderName;
  String? cardAliasName;

  String? customerId;
  String? lastFourDigits;
  String? transationalType;
  String? brandType;
  int? expirationMonth;
  String? urlFlag;
  int? expirationYear;
  String? userId;
  String? cardId;
  String? tipoDocumento;
  String? numeroDocumento;
  String? flagCard;
  String? cvv;

  CreditCardUserModel({
    this.id,
    this.cardHolderName,
    this.customerId,
    this.lastFourDigits,
    this.transationalType,
    this.brandType,
    this.expirationMonth,
    this.expirationYear,
    this.urlFlag,
    this.userId,
    this.cardId,
    this.flagCard,
    this.tipoDocumento,
    this.numeroDocumento,
    this.cardAliasName,
    this.cvv
  });

  CreditCardUserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardHolderName = json['cardName'];
    customerId = json['customerId'];
    lastFourDigits = json['lastFourDigits'];
    transationalType = json['transationalType'];
    brandType = json['cardType'];
    expirationMonth = json['expirationMonth'];
    expirationYear = json['expirationYear'];
    urlFlag = json['urlFlag'];
    userId = json['userId'];
    cardId = json['cardId'];
    numeroDocumento = json['numeroDocumento'];
    tipoDocumento = json['tipoDocumento'];
    flagCard = json['flagCard'];
    cvv = json['cvv'];
    cardAliasName = json['cardAliasName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['cardName'] = cardHolderName;
    data['customerId'] = customerId;
    data['lastFourDigits'] = lastFourDigits;
    data['transationalType'] = transationalType;
    data['cardType'] = brandType;
    data['expirationMonth'] = expirationMonth;
    data['expirationYear'] = expirationYear;
    data['urlFlag'] = urlFlag;
    data['userId'] = userId;
    data['cardId'] = cardId;
    data['flagCard'] = flagCard;
    data['cardAliasName'] = cardAliasName;
    data['flagCard'] = flagCard;
    data['cvv'] = cvv;
    data['numeroDocumento'] = numeroDocumento;
    data['tipoDocumento'] = tipoDocumento;
    return data;
  }
}
