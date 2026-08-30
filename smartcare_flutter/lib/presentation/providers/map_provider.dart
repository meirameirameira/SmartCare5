import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Provider do mapa de dispositivos IoT.
class MapProvider extends ChangeNotifier {
  MapProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) load();
  }

  final DeviceRepository _repository;

  static const defaultLat = -23.5505;
  static const defaultLng = -46.6333;

  List<SmartDevice> devices = const [];
  SmartDevice? selectedDevice;
  bool isLoading = true;

  /// Falha de localização: exibida como aviso não bloqueante no mapa.
  AppFailure? locationFailure;

  double? _lat;
  double? _lng;

  double get centerLat => _lat ?? defaultLat;
  double get centerLng => _lng ?? defaultLng;

  /// `true` quando o mapa está centrado na posição real do paciente.
  bool get hasUserLocation => _lat != null && _lng != null;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    devices = (await _repository.loadDevices()).valueOrNull ?? const [];

    final location = await _repository.currentLocation();
    location.when(
      ok: (coords) {
        _lat = coords.lat;
        _lng = coords.lng;
        locationFailure = null;
      },
      err: (f) {
        locationFailure = f;
        debugPrint('[MapProvider] usando localização padrão: ${f.message}');
      },
    );

    isLoading = false;
    notifyListeners();
  }

  void selectDevice(SmartDevice? device) {
    selectedDevice = device;
    notifyListeners();
  }

  /// Filtra os dispositivos por tipo — usado pelos chips de filtro do mapa.
  List<SmartDevice> devicesOfType(DeviceType? type) =>
      type == null ? devices : devices.where((d) => d.type == type).toList();
}
