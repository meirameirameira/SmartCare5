import 'package:geolocator/geolocator.dart';

import '../../core/error/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/demo_catalog.dart';

/// Dispositivos IoT do ecossistema SmartCare e localização do paciente.
///
/// A negação de permissão agora vira uma [PermissionFailure] tipada, que a tela
/// exibe como aviso — antes o erro era engolido e o mapa ficava em São Paulo
/// sem explicar o motivo ao usuário.
class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl();

  static const fallbackLocation = (lat: -23.5505, lng: -46.6333);

  @override
  Future<Result<List<SmartDevice>>> loadDevices() =>
      Result.guard(() async => DemoCatalog.devices);

  @override
  Future<Result<({double lat, double lng})>> currentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Err(PermissionFailure('localização'));
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));

      return Ok((lat: position.latitude, lng: position.longitude));
    } catch (e) {
      return Err(UnexpectedFailure(cause: e));
    }
  }
}
