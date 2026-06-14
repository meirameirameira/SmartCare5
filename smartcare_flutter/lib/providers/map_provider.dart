import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class MapProvider extends ChangeNotifier {
  Position? userPosition;
  List<SmartDevice> devices = [];
  SmartDevice? selectedDevice;
  bool isLoading = true;

  // Coordenadas padrão: centro de São Paulo
  static const defaultLat = -23.5505;
  static const defaultLng = -46.6333;

  MapProvider() {
    _init();
  }

  Future<void> _init() async {
    // Dispositivos SmartCare 5.0 mockados em São Paulo
    devices = const [
      SmartDevice(
        id: 's1', name: 'Sensor Cardíaco — Casa', type: DeviceType.sensor,
        lat: -23.5505, lng: -46.6333, active: true, status: 'Online · 72 bpm',
      ),
      SmartDevice(
        id: 's2', name: 'Sensor Glicêmico — Sala', type: DeviceType.sensor,
        lat: -23.5520, lng: -46.6360, active: true, status: 'Online · 104 mg/dL',
      ),
      SmartDevice(
        id: 'c1', name: 'Câmera Segurança — Entrada', type: DeviceType.camera,
        lat: -23.5490, lng: -46.6310, active: true, status: 'Streaming ativo',
      ),
      SmartDevice(
        id: 'f1', name: 'Farmácia Leroy Health', type: DeviceType.pharmacy,
        lat: -23.5560, lng: -46.6410, active: true, status: 'Pedido em rota',
      ),
      SmartDevice(
        id: 'h1', name: 'Hospital das Clínicas', type: DeviceType.hospital,
        lat: -23.5554, lng: -46.6720, active: true, status: 'Referência',
      ),
      SmartDevice(
        id: 'h2', name: 'UPA Lapa', type: DeviceType.hospital,
        lat: -23.5250, lng: -46.6900, active: true, status: 'Urgência',
      ),
    ];

    // Tenta obter localização real
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Usa localização padrão (São Paulo)
    }

    isLoading = false;
    notifyListeners();
  }

  void selectDevice(SmartDevice? device) {
    selectedDevice = device;
    notifyListeners();
  }

  double get centerLat => userPosition?.latitude ?? defaultLat;
  double get centerLng => userPosition?.longitude ?? defaultLng;
}
