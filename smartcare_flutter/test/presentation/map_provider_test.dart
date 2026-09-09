import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/result/result.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/repositories/repositories.dart';
import 'package:smartcare_flutter/presentation/providers/map_provider.dart';

class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository({this.location, this.devices = const []});

  final ({double lat, double lng})? location;
  final List<SmartDevice> devices;

  AppFailure? searchFailure;

  /// Coordenadas recebidas em cada busca, na ordem.
  final List<({double lat, double lng})> searchedAt = [];

  @override
  Future<Result<({double lat, double lng})>> currentLocation() async =>
      location == null
          ? const Err(PermissionFailure('localização'))
          : Ok(location!);

  @override
  Future<Result<List<SmartDevice>>> nearbyCarePoints({
    required double lat,
    required double lng,
  }) async {
    searchedAt.add((lat: lat, lng: lng));
    final failure = searchFailure;
    return failure == null ? Ok(devices) : Err(failure);
  }
}

SmartDevice _device(String id) => SmartDevice(
      id: id,
      name: 'Ponto $id',
      type: DeviceType.pharmacy,
      lat: -1,
      lng: -1,
    );

void main() {
  test('busca atendimento em volta da posição real do usuário', () async {
    final repo = _FakeDeviceRepository(
      location: (lat: -22.9068, lng: -43.1729),
      devices: [_device('a')],
    );

    final provider = MapProvider(repo, autoStart: false);
    await provider.load();

    expect(repo.searchedAt.single, (lat: -22.9068, lng: -43.1729));
    expect(provider.hasUserLocation, isTrue);
    expect(provider.devices, hasLength(1));
    expect(provider.isLoading, isFalse);
  });

  test('sem permissão, busca em volta da posição padrão e avisa o motivo',
      () async {
    final repo = _FakeDeviceRepository(devices: [_device('a')]);

    final provider = MapProvider(repo, autoStart: false);
    await provider.load();

    expect(repo.searchedAt.single,
        (lat: MapProvider.defaultLat, lng: MapProvider.defaultLng));
    expect(provider.hasUserLocation, isFalse);
    expect(provider.locationFailure, isA<PermissionFailure>());
    expect(provider.devices, hasLength(1));
  });

  test('falha na busca esvazia o mapa e expõe o erro para nova tentativa',
      () async {
    final repo = _FakeDeviceRepository(
      location: (lat: -22.9068, lng: -43.1729),
      devices: [_device('a')],
    )..searchFailure = const NetworkFailure();

    final provider = MapProvider(repo, autoStart: false);
    await provider.load();

    expect(provider.devices, isEmpty);
    expect(provider.searchFailure, isA<NetworkFailure>());

    repo.searchFailure = null;
    await provider.retrySearch();

    expect(provider.searchFailure, isNull);
    expect(provider.devices, hasLength(1));
    expect(repo.searchedAt, hasLength(2));
  });

  test('descarta a seleção quando o ponto some da nova busca', () async {
    final repo = _FakeDeviceRepository(
      location: (lat: -22.9068, lng: -43.1729),
      devices: [_device('a')],
    );

    final provider = MapProvider(repo, autoStart: false);
    await provider.load();
    provider.selectDevice(provider.devices.single);
    expect(provider.selectedDevice, isNotNull);

    repo.searchFailure = const NetworkFailure();
    await provider.retrySearch();

    expect(provider.selectedDevice, isNull);
  });
}
