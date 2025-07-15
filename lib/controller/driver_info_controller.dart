import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/review_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class DriverInfoController extends GetxController {
  // Controle para notificação aos 500m
  RxBool notificationSent500m = false.obs;
  RxBool driverArrived = false.obs;

  // Observable para dados principais
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxBool isLoading = true.obs;

  // Observables para informações de tempo e distância
  RxString estimatedTime = "".obs;
  RxString estimatedDistance = "".obs;

  // Controlador do mapa
  GoogleMapController? mapController;

  // Marcadores e linhas do mapa
  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;

  // Para desenhar as rotas
  PolylinePoints polylinePoints = PolylinePoints();

  // Ícones personalizados para o mapa
  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  // Stream subscription para atualizações em tempo real
  StreamSubscription<DocumentSnapshot>? orderSubscription;
  StreamSubscription<DocumentSnapshot>? driverSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    orderSubscription?.cancel();
    driverSubscription?.cancel();
    super.onClose();
  }

  // Inicializar dados da tela
  void _initializeData() async {
    try {
      // Receber dados dos argumentos
      final arguments = Get.arguments;
      if (arguments != null) {
        orderModel.value = arguments['orderModel'] ?? OrderModel();
      }

      // Buscar dados do motorista
      await _loadDriverData();

      // Configurar ícones do mapa
      await _setupMapIcons();

      // Iniciar listeners para atualizações em tempo real
      _startRealTimeListeners();

      isLoading.value = false;
    } catch (e) {
      print("Erro ao inicializar dados: $e");
      isLoading.value = false;
    }
  }

  // Carregar dados do motorista
  Future<void> _loadDriverData() async {
    if (orderModel.value.driverId != null) {
      DriverUserModel? driver = await FireStoreUtils.getDriver(orderModel.value.driverId!);
      if (driver != null) {
        driverModel.value = driver;
      }
    }
  }

  // Configurar ícones personalizados para o mapa com tamanhos muito menores
  Future<void> _setupMapIcons() async {
    try {
      // Ícones de origem e destino em tamanho reduzido
      final Uint8List departureBytes = await Constant().getBytesFromAsset('assets/images/pickup.png', 50);
      final Uint8List destinationBytes = await Constant().getBytesFromAsset('assets/images/dropoff.png', 50);

      // Ícone do carro muito menor para ser realista
      final Uint8List driverBytes = await Constant().getBytesFromAsset('assets/images/ic_cab.png', 50);

      departureIcon = BitmapDescriptor.fromBytes(departureBytes);
      destinationIcon = BitmapDescriptor.fromBytes(destinationBytes);
      driverIcon = BitmapDescriptor.fromBytes(driverBytes);
    } catch (e) {
      print("Erro ao configurar ícones do mapa: $e");
      _setupDefaultIcons();
    }
  }

  // Configurar ícones padrão caso os assets não existam
  void _setupDefaultIcons() {
    departureIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  // Iniciar listeners para atualizações em tempo real
  void _startRealTimeListeners() {
    // Listener para atualizações da ordem
    if (orderModel.value.id != null) {
      orderSubscription = FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderModel.value.id)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          OrderModel previousOrder = orderModel.value;
          orderModel.value = OrderModel.fromJson(snapshot.data()!);

          // Verificar se a corrida foi completada
          _checkRideCompletion(previousOrder);

          _updateMapWithNewData();
        }
      });
    }

    // Listener para atualizações da localização do motorista
    if (orderModel.value.driverId != null) {
      driverSubscription = FirebaseFirestore.instance
          .collection(CollectionName.driverUsers)
          .doc(orderModel.value.driverId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          driverModel.value = DriverUserModel.fromJson(snapshot.data()!);
          _updateDriverLocationOnMap();
        }
      });
    }
  }

  // Verificar se a corrida foi completada e navegar para avaliação
  void _checkRideCompletion(OrderModel previousOrder) {
    // Se mudou de qualquer status para rideComplete
    if (previousOrder.status != Constant.rideComplete &&
        orderModel.value.status == Constant.rideComplete) {

      // Delay para garantir que a UI foi atualizada
      Future.delayed(const Duration(milliseconds: 500), () {
        _showRatingAndNavigateHome();
      });
    }
  }

  // Mostrar avaliação e navegar para home
  void _showRatingAndNavigateHome() {
    // Fechar a tela atual e voltar para home
    Get.back();

    // Delay pequeno para garantir navegação suave
    Future.delayed(const Duration(milliseconds: 300), () {
      _showDriverRatingBottomSheet();
    });
  }

  // Mostrar bottom sheet de avaliação do motorista
  void _showDriverRatingBottomSheet() {
    Get.bottomSheet(
      _buildRatingBottomSheet(),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }

  // Construir bottom sheet de avaliação
  Widget _buildRatingBottomSheet() {
    RxDouble rating = 5.0.obs;
    RxString comment = "".obs;
    TextEditingController commentController = TextEditingController();

    return Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Indicador de drag
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Título
            Text(
              'Avalie sua corrida',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Como foi sua experiência com o motorista?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Foto e nome do motorista
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driverModel.value.profilePic ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGray,
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGray,
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  driverModel.value.fullName ?? 'Motorista',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${driverModel.value.vehicleInformation?.vehicleType ?? 'Veículo'} • ${driverModel.value.vehicleInformation?.vehicleNumber ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sistema de avaliação por estrelas
            Obx(() => RatingBar.builder(
              initialRating: rating.value,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 45,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppColors.ratingColour,
              ),
              onRatingUpdate: (newRating) {
                rating.value = newRating;
              },
            )),

            const SizedBox(height: 24),

            // Campo de comentário
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: commentController,
                maxLines: 3,
                onChanged: (value) => comment.value = value,
                decoration: InputDecoration(
                  hintText: 'Deixe um comentário (opcional)',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),

            const Spacer(),

            // Botões
            Row(
              children: [
                // Botão pular
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipRating(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Pular',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Botão enviar avaliação
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submitRating(rating.value, commentController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Enviar Avaliação',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pular avaliação
  void _skipRating() {
    Get.back(); // Fechar bottom sheet
    ShowToastDialog.showToast('Obrigado por usar nosso serviço!');
  }

  // Enviar avaliação
  void _submitRating(double rating, String comment) async {
    try {
      ShowToastDialog.showLoader('Enviando avaliação...');

      // Criar modelo de review
      ReviewModel reviewModel = ReviewModel(
        id: orderModel.value.id,
        comment: comment.isEmpty ? 'Sem comentários' : comment,
        rating: rating.toString(),
        customerId: FireStoreUtils.getCurrentUid(),
        driverId: driverModel.value.id,
        date: Timestamp.now()
      );

      // Salvar review
      await FireStoreUtils.setReview(reviewModel);

      // Atualizar rating do motorista
      await _updateDriverRating(rating);

      ShowToastDialog.closeLoader();
      Get.back(); // Fechar bottom sheet

      ShowToastDialog.showToast('Avaliação enviada com sucesso!');

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Erro ao enviar avaliação');
      print("Erro ao enviar avaliação: $e");
    }
  }

  // Atualizar rating do motorista
  Future<void> _updateDriverRating(double newRating) async {
    try {
      // Buscar dados atuais do motorista
      DriverUserModel? currentDriver = await FireStoreUtils.getDriver(driverModel.value.id!);

      if (currentDriver != null) {
        // Calcular novo rating
        double currentSum = double.parse(currentDriver.reviewsSum ?? '0.0');
        double currentCount = double.parse(currentDriver.reviewsCount ?? '0.0');

        double newSum = currentSum + newRating;
        double newCount = currentCount + 1;

        // Atualizar motorista
        currentDriver.reviewsSum = newSum.toString();
        currentDriver.reviewsCount = newCount.toString();

        await FireStoreUtils.updateDriver(currentDriver);
      }
    } catch (e) {
      print("Erro ao atualizar rating do motorista: $e");
    }
  }

  // Atualizar mapa com novos dados
  void _updateMapWithNewData() {
    if (mapController != null) {
      _addMarkersToMap();
      _drawRoute();

      // Aplicar zoom dinâmico quando dados mudarem
      _applyInitialDynamicZoom();
    }
  }

  // Atualizar apenas a localização do motorista no mapa com zoom dinâmico
  void _updateDriverLocationOnMap() {
    if (mapController != null && driverModel.value.location != null) {
      _updateDriverMarker();
      _calculateEstimatedTimeAndDistance();

      // Aplicar zoom dinâmico quando motorista está se aproximando
      if (orderModel.value.status == Constant.rideActive) {
        _applyDynamicZoom();
      }
    }
  }

  // Aplicar zoom dinâmico baseado na proximidade do motorista (INVERTIDO - mais perto = menos zoom)
  void _applyDynamicZoom() {
    if (driverModel.value.location != null &&
        orderModel.value.sourceLocationLAtLng != null) {

      double distance = _calculateDistance(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        orderModel.value.sourceLocationLAtLng!.latitude!,
        orderModel.value.sourceLocationLAtLng!.longitude!,
      );

      double zoomLevel;

      // Zoom INVERTIDO: quanto mais próximo, MENOR o zoom (visão mais ampla)
      if (distance < 0.1) { // Menos de 100 metros - CHEGOU
        zoomLevel = 16.0;
        _checkDriverArrival(distance);
      } else if (distance < 0.2) { // Menos de 200 metros
        zoomLevel = 15.5;
      } else if (distance < 0.5) { // Menos de 500 metros
        zoomLevel = 15.0;
        _checkProximityNotification(distance);
      } else if (distance < 1.0) { // Menos de 1 km
        zoomLevel = 14.5;
      } else if (distance < 2.0) { // Menos de 2 km
        zoomLevel = 14.0;
      } else {
        zoomLevel = 13.5; // Distante - zoom mais próximo para acompanhar
      }

      // Centralizar no motorista quando muito próximo, senão entre os dois pontos
      LatLng centerPoint;
      if (distance < 0.2) {
        // Foco no motorista quando muito próximo
        centerPoint = LatLng(
          driverModel.value.location!.latitude!,
          driverModel.value.location!.longitude!,
        );
      } else {
        // Centralizar entre motorista e passageiro
        centerPoint = LatLng(
          (driverModel.value.location!.latitude! + orderModel.value.sourceLocationLAtLng!.latitude!) / 2,
          (driverModel.value.location!.longitude! + orderModel.value.sourceLocationLAtLng!.longitude!) / 2,
        );
      }

      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: centerPoint,
            zoom: zoomLevel,
          ),
        ),
      );
    }
  }

  // Verificar se deve enviar notificação aos 500m
  void _checkProximityNotification(double distance) {
    if (distance <= 0.5 && !notificationSent500m.value) {
      notificationSent500m.value = true;
      _sendProximityNotification();
    }
  }

  // Verificar se motorista chegou (menos de 100m)
  void _checkDriverArrival(double distance) {
    if (distance <= 0.1 && !driverArrived.value) {
      driverArrived.value = true;
      // Atualizar status para "Motorista esperando" será feito via getter
    }
  }

  // Enviar push notification aos 500m
  void _sendProximityNotification() async {
    try {
      // Buscar dados do usuário atual
      UserModel? currentUser = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());

      if (currentUser?.fcmToken != null) {
        String timeText = estimatedTime.value.isNotEmpty ? estimatedTime.value : "alguns minutos";

        Map<String, dynamic> payload = {
          "type": "driver_approaching",
          "orderId": orderModel.value.id,
          "driverId": driverModel.value.id,
          "estimatedTime": timeText,
        };

        await SendNotification.sendOneNotification(
          token: currentUser!.fcmToken!,
          title: "Motorista se aproximando! 🚗",
          body: "Seu motorista ${driverModel.value.fullName ?? 'está'} chegará em $timeText. Prepare-se!",
          payload: payload,
        );
      }
    } catch (e) {
      print("Erro ao enviar notificação de proximidade: $e");
    }
  }

  // Callback quando o mapa é criado
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _addMarkersToMap();
    _drawRoute();
    _calculateEstimatedTimeAndDistance();

    // Aplicar zoom dinâmico inicial baseado na distância
    _applyInitialDynamicZoom();
  }

  // Aplicar zoom dinâmico inicial baseado na distância entre motorista e passageiro
  void _applyInitialDynamicZoom() {
    if (mapController != null) {
      if (orderModel.value.status == Constant.rideActive &&
          driverModel.value.location != null &&
          orderModel.value.sourceLocationLAtLng != null) {
        // Para rideActive: zoom baseado na distância motorista-passageiro
        _applyDynamicZoom();
      } else if (orderModel.value.sourceLocationLAtLng != null &&
          orderModel.value.destinationLocationLAtLng != null) {
        // Para outros status: zoom baseado na distância origem-destino
        _applyRouteBasedZoom();
      }
    }
  }

  // Aplicar zoom baseado na rota origem-destino
  void _applyRouteBasedZoom() {
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {

      double distance = _calculateDistance(
        orderModel.value.sourceLocationLAtLng!.latitude!,
        orderModel.value.sourceLocationLAtLng!.longitude!,
        orderModel.value.destinationLocationLAtLng!.latitude!,
        orderModel.value.destinationLocationLAtLng!.longitude!,
      );

      double zoomLevel;
      double padding;

      // Zoom baseado na distância da rota total
      if (distance < 1.0) { // Menos de 1 km
        zoomLevel = 15.0;
        padding = 80.0;
      } else if (distance < 3.0) { // Menos de 3 km
        zoomLevel = 14.0;
        padding = 100.0;
      } else if (distance < 5.0) { // Menos de 5 km
        zoomLevel = 13.5;
        padding = 120.0;
      } else if (distance < 10.0) { // Menos de 10 km
        zoomLevel = 13.0;
        padding = 150.0;
      } else if (distance < 20.0) { // Menos de 20 km
        zoomLevel = 12.0;
        padding = 180.0;
      } else {
        zoomLevel = 11.0; // Viagens muito longas
        padding = 200.0;
      }

      // Aplicar bounds para mostrar origem e destino
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
                math.min(orderModel.value.sourceLocationLAtLng!.latitude!,
                    orderModel.value.destinationLocationLAtLng!.latitude!),
                math.min(orderModel.value.sourceLocationLAtLng!.longitude!,
                    orderModel.value.destinationLocationLAtLng!.longitude!)
            ),
            northeast: LatLng(
                math.max(orderModel.value.sourceLocationLAtLng!.latitude!,
                    orderModel.value.destinationLocationLAtLng!.latitude!),
                math.max(orderModel.value.sourceLocationLAtLng!.longitude!,
                    orderModel.value.destinationLocationLAtLng!.longitude!)
            ),
          ),
          padding,
        ),
      );
    }
  }

  // Adicionar marcadores no mapa
  void _addMarkersToMap() {
    markers.clear();

    // Marcador de origem
    if (orderModel.value.sourceLocationLAtLng != null && departureIcon != null) {
      _addMarker(
        id: "departure",
        position: LatLng(
          orderModel.value.sourceLocationLAtLng!.latitude!,
          orderModel.value.sourceLocationLAtLng!.longitude!,
        ),
        icon: departureIcon!,
        infoWindow: const InfoWindow(title: "Ponto de Partida"),
      );
    }

    // Marcador de destino
    if (orderModel.value.destinationLocationLAtLng != null && destinationIcon != null) {
      _addMarker(
        id: "destination",
        position: LatLng(
          orderModel.value.destinationLocationLAtLng!.latitude!,
          orderModel.value.destinationLocationLAtLng!.longitude!,
        ),
        icon: destinationIcon!,
        infoWindow: const InfoWindow(title: "Destino"),
      );
    }

    // Marcador do motorista
    _updateDriverMarker();
  }

  // Atualizar marcador do motorista
  void _updateDriverMarker() {
    if (driverModel.value.location != null && driverIcon != null) {
      _addMarker(
        id: "driver",
        position: LatLng(
          driverModel.value.location!.latitude!,
          driverModel.value.location!.longitude!,
        ),
        icon: driverIcon!,
        rotation: driverModel.value.rotation ?? 0.0,
        infoWindow: InfoWindow(title: driverModel.value.fullName ?? "Motorista"),
      );
    }
  }

  // Adicionar marcador individual
  void _addMarker({
    required String id,
    required LatLng position,
    required BitmapDescriptor icon,
    double rotation = 0.0,
    InfoWindow infoWindow = const InfoWindow(),
  }) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      position: position,
      icon: icon,
      rotation: rotation,
      infoWindow: infoWindow,
    );
    markers[markerId] = marker;
  }

  // Desenhar rota no mapa baseado no status da corrida
  void _drawRoute() async {
    // Verificar status da corrida para determinar qual rota mostrar
    if (orderModel.value.status == Constant.rideActive) {
      // Status ATIVO: Mostrar rota do motorista até o passageiro (origem)
      await _drawDriverToPassengerRoute();
    } else if (orderModel.value.status == Constant.rideInProgress) {
      // Status EM PROGRESSO: Mostrar rota do passageiro até o destino
      await _drawPassengerToDestinationRoute();
    } else {
      // Status INICIAL: Mostrar rota completa (origem → destino)
      await _drawCompleteRoute();
    }
  }

  // Rota do motorista até o passageiro (origem)
  Future<void> _drawDriverToPassengerRoute() async {
    if (driverModel.value.location != null &&
        orderModel.value.sourceLocationLAtLng != null) {

      List<LatLng> polylineCoordinates = [];

      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(
          driverModel.value.location!.latitude!,
          driverModel.value.location!.longitude!,
        ),
        destination: PointLatLng(
          orderModel.value.sourceLocationLAtLng!.latitude!,
          orderModel.value.sourceLocationLAtLng!.longitude!,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: polylineRequest,
        googleApiKey: Constant.mapAPIKey,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _addPolyLine(polylineCoordinates, AppColors.primary);
      }
    }
  }

  // Rota do passageiro até o destino
  Future<void> _drawPassengerToDestinationRoute() async {
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {

      List<LatLng> polylineCoordinates = [];

      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(
          orderModel.value.sourceLocationLAtLng!.latitude!,
          orderModel.value.sourceLocationLAtLng!.longitude!,
        ),
        destination: PointLatLng(
          orderModel.value.destinationLocationLAtLng!.latitude!,
          orderModel.value.destinationLocationLAtLng!.longitude!,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: polylineRequest,
        googleApiKey: Constant.mapAPIKey,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _addPolyLine(polylineCoordinates, AppColors.success);
      }
    }
  }

  // Rota completa (origem → destino) - para visualização inicial
  Future<void> _drawCompleteRoute() async {
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {

      List<LatLng> polylineCoordinates = [];

      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(
          orderModel.value.sourceLocationLAtLng!.latitude!,
          orderModel.value.sourceLocationLAtLng!.longitude!,
        ),
        destination: PointLatLng(
          orderModel.value.destinationLocationLAtLng!.latitude!,
          orderModel.value.destinationLocationLAtLng!.longitude!,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: polylineRequest,
        googleApiKey: Constant.mapAPIKey,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _addPolyLine(polylineCoordinates, const Color(0xFF7C3AED));
      }
    }
  }

  // Adicionar polyline ao mapa com cor específica
  void _addPolyLine(List<LatLng> polylineCoordinates, Color color) {
    polyLines.clear(); // Limpar rotas anteriores

    PolylineId id = const PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      color: color,
      width: 5,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
    polyLines[id] = polyline;

    // Ajustar câmera para mostrar toda a rota
    _updateCameraToShowRoute(polylineCoordinates);
  }

  // Atualizar câmera para mostrar toda a rota com zoom dinâmico
  void _updateCameraToShowRoute(List<LatLng> coordinates) {
    if (mapController != null && coordinates.isNotEmpty) {
      double minLat = coordinates.first.latitude;
      double maxLat = coordinates.first.latitude;
      double minLng = coordinates.first.longitude;
      double maxLng = coordinates.first.longitude;

      for (LatLng coord in coordinates) {
        minLat = coord.latitude < minLat ? coord.latitude : minLat;
        maxLat = coord.latitude > maxLat ? coord.latitude : maxLat;
        minLng = coord.longitude < minLng ? coord.longitude : minLng;
        maxLng = coord.longitude > maxLng ? coord.longitude : maxLng;
      }

      // Calcular padding baseado na distância (efeito Uber)
      double padding = _calculateDynamicPadding();

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          padding,
        ),
      );
    }
  }

  // Calcular padding dinâmico baseado na proximidade (usado para bounds)
  double _calculateDynamicPadding() {
    if (orderModel.value.status == Constant.rideActive &&
        driverModel.value.location != null &&
        orderModel.value.sourceLocationLAtLng != null) {

      // Calcular distância entre motorista e passageiro
      double distance = _calculateDistance(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        orderModel.value.sourceLocationLAtLng!.latitude!,
        orderModel.value.sourceLocationLAtLng!.longitude!,
      );

      // Padding dinâmico: quanto mais próximo, menor o padding (mais zoom)
      if (distance < 0.1) { // Menos de 100 metros
        return 40.0; // Padding menor = mais zoom
      } else if (distance < 0.5) { // Menos de 500 metros
        return 60.0;
      } else if (distance < 1.0) { // Menos de 1 km
        return 80.0;
      } else if (distance < 2.0) { // Menos de 2 km
        return 100.0;
      } else if (distance < 5.0) { // Menos de 5 km
        return 130.0;
      } else {
        return 160.0; // Padding maior = menos zoom
      }
    }

    // Para outros status, usar padding baseado na distância da rota
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {

      double routeDistance = _calculateDistance(
        orderModel.value.sourceLocationLAtLng!.latitude!,
        orderModel.value.sourceLocationLAtLng!.longitude!,
        orderModel.value.destinationLocationLAtLng!.latitude!,
        orderModel.value.destinationLocationLAtLng!.longitude!,
      );

      if (routeDistance < 1.0) return 80.0;
      if (routeDistance < 5.0) return 120.0;
      if (routeDistance < 10.0) return 150.0;
      return 180.0;
    }

    return 120.0; // Padding padrão
  }

  // Calcular distância entre dois pontos em km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371; // Raio da Terra em km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return radiusOfEarth * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Calcular tempo e distância estimados baseado no status
  void _calculateEstimatedTimeAndDistance() async {
    if (orderModel.value.status == Constant.rideActive) {
      // Calcular tempo do motorista até o passageiro
      await _calculateDriverToPassengerTime();
    } else if (orderModel.value.status == Constant.rideInProgress) {
      // Calcular tempo do passageiro até o destino
      await _calculatePassengerToDestinationTime();
    }
  }

  // Calcular tempo do motorista até o passageiro
  Future<void> _calculateDriverToPassengerTime() async {
    if (driverModel.value.location != null &&
        orderModel.value.sourceLocationLAtLng != null) {

      try {
        final result = await Constant.getDurationDistance(
          LatLng(
            driverModel.value.location!.latitude!,
            driverModel.value.location!.longitude!,
          ),
          LatLng(
            orderModel.value.sourceLocationLAtLng!.latitude!,
            orderModel.value.sourceLocationLAtLng!.longitude!,
          ),
        );

        if (result != null && result.rows!.isNotEmpty) {
          final element = result.rows!.first.elements!.first;

          if (element.duration != null && element.distance != null) {
            estimatedTime.value = element.duration!.text ?? '';
            estimatedDistance.value = element.distance!.text ?? '';
          }
        }
      } catch (e) {
        print("Erro ao calcular tempo e distância: $e");
      }
    }
  }

  // Calcular tempo do passageiro até o destino
  Future<void> _calculatePassengerToDestinationTime() async {
    if (orderModel.value.sourceLocationLAtLng != null &&
        orderModel.value.destinationLocationLAtLng != null) {

      try {
        final result = await Constant.getDurationDistance(
          LatLng(
            orderModel.value.sourceLocationLAtLng!.latitude!,
            orderModel.value.sourceLocationLAtLng!.longitude!,
          ),
          LatLng(
            orderModel.value.destinationLocationLAtLng!.latitude!,
            orderModel.value.destinationLocationLAtLng!.longitude!,
          ),
        );

        if (result != null && result.rows!.isNotEmpty) {
          final element = result.rows!.first.elements!.first;

          if (element.duration != null && element.distance != null) {
            estimatedTime.value = element.duration!.text ?? '';
            estimatedDistance.value = element.distance!.text ?? '';
          }
        }
      } catch (e) {
        print("Erro ao calcular tempo e distância: $e");
      }
    }
  }

  // Centrar mapa na localização do motorista
  void centerOnDriver() {
    if (mapController != null && driverModel.value.location != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            driverModel.value.location!.latitude!,
            driverModel.value.location!.longitude!,
          ),
          16.0,
        ),
      );
    }
  }

  // Centrar mapa na rota completa
  void centerOnRoute() {
    if (polyLines.isNotEmpty) {
      final routePolyline = polyLines.values.first;
      _updateCameraToShowRoute(routePolyline.points);
    }
  }

  // Getter para verificar se o motorista está se aproximando
  bool get isDriverApproaching {
    if (estimatedTime.value.isEmpty) return false;

    // Extrair número de minutos do texto (ex: "5 min" -> 5)
    final timeText = estimatedTime.value.toLowerCase();
    final numbers = RegExp(r'\d+').allMatches(timeText);

    if (numbers.isNotEmpty) {
      final minutes = int.tryParse(numbers.first.group(0) ?? '0') ?? 0;
      return minutes <= 5; // Considerado "se aproximando" se for 5 min ou menos
    }

    return false;
  }

  // Getter para status da corrida formatado baseado no status real
  String get rideStatusText {
    switch (orderModel.value.status) {
      case Constant.rideActive:
        return "Motorista a caminho";
      case Constant.rideInProgress:
        return "Viagem em andamento";
      case Constant.rideComplete:
        return "Viagem finalizada";
      case Constant.rideCanceled:
        return "Viagem cancelada";
      default:
        return "Aguardando motorista";
    }
  }

  // Getter para mensagem de tempo baseado no status
  String get timeLabel {
    switch (orderModel.value.status) {
      case Constant.rideActive:
        return "Chegada em";
      case Constant.rideInProgress:
        return "Destino em";
      default:
        return "Tempo estimado";
    }
  }

  // Getter para mensagem de distância baseado no status
  String get distanceLabel {
    switch (orderModel.value.status) {
      case Constant.rideActive:
        return "Distância";
      case Constant.rideInProgress:
        return "Faltam";
      default:
        return "Distância";
    }
  }

  // Função para verificar se deve mostrar OTP
  bool get shouldShowOTP {
    return orderModel.value.status == Constant.rideActive;
  }

  // Função para atualizar status quando OTP for confirmado
  void confirmOTP() async {
    if (orderModel.value.status == Constant.rideActive) {
      orderModel.value.status = Constant.rideInProgress;
      await FireStoreUtils.setOrder(orderModel.value);

      // Redesenhar rota para mostrar do passageiro ao destino
      _drawRoute();
      _calculateEstimatedTimeAndDistance();
    }
  }

  // Getter para cor do status
  Color get rideStatusColor {
    switch (orderModel.value.status) {
      case Constant.rideActive:
        return const Color(0xFF7C3AED);
      case Constant.rideInProgress:
        return const Color(0xFF059669);
      case Constant.rideComplete:
        return const Color(0xFF10B981);
      case Constant.rideCanceled:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
