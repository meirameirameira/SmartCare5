import 'dart:math' as math;

import '../../../core/network/api_client.dart';
import '../../../domain/entities/entities.dart';

/// Busca farmácias e hospitais reais em volta de uma coordenada.
///
/// Usa a Overpass API, que consulta a mesma base do OpenStreetMap que desenha
/// os tiles do mapa — então cada marcador cai exatamente sobre o
/// estabelecimento renderizado. Não exige chave nem faturamento.
class OverpassDataSource {
  OverpassDataSource(this._client, {this.endpoint = publicEndpoint});

  final ApiClient _client;

  /// Instância pública da Overpass. Sobrescrita nos testes.
  final String endpoint;

  static const publicEndpoint = 'https://overpass-api.de/api/interpreter';

  /// Raio padrão de busca. Cobre o bairro sem devolver centenas de pontos.
  static const defaultRadiusMeters = 2500;

  /// Cotas por tipo. Um teto único não serve: a Overpass devolve os nós antes
  /// das vias, e hospital costuma ser mapeado como polígono enquanto farmácia
  /// é um ponto. Com limite único as farmácias enchiam a lista e os hospitais
  /// grandes ficavam de fora — em Copacabana, 39 farmácias e 1 hospital.
  static const maxPharmacies = 25;
  static const maxHospitals = 20;

  /// Teto de segurança na consulta, alto o bastante para não cortar por tipo.
  static const _queryLimit = 400;

  /// Raio em que um prédio marcado como hospital é tratado como pavilhão de um
  /// complexo maior já presente na lista.
  static const _annexRadiusMeters = 250.0;

  /// Raio em que dois hospitais de nome equivalente são a mesma instituição
  /// mapeada mais de uma vez.
  static const _hospitalDuplicateRadiusMeters = 300.0;

  /// Farmácias de rede ficam perto umas das outras e são lojas distintas, então
  /// só viram duplicata quando praticamente sobrepostas.
  static const _pharmacyDuplicateRadiusMeters = 40.0;

  /// A Overpass pede uso moderado: repetir a mesma área dentro desta janela
  /// devolve o resultado já em memória em vez de uma nova requisição.
  static const cacheTtl = Duration(minutes: 10);

  _CachedSearch? _cache;

  Future<List<SmartDevice>> nearbyCarePoints({
    required double lat,
    required double lng,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final cached = _cache;
    if (cached != null && cached.covers(lat, lng, radiusMeters)) {
      return cached.devices;
    }

    final query = '''
[out:json][timeout:25];
nwr["amenity"~"^(pharmacy|hospital)\$"]["name"](around:$radiusMeters,$lat,$lng);
out center $_queryLimit;
''';

    final elements = await _client.getJson<List<dynamic>>(
      endpoint,
      query: {'data': query},
      decode: (json) => (json['elements'] as List<dynamic>?) ?? const [],
    );

    final candidates = <_Candidate>[];
    for (final element in elements) {
      final candidate = _toCandidate(element);
      if (candidate != null) candidates.add(candidate);
    }

    // Os mais próximos primeiro: é o que interessa a quem precisa de socorro.
    candidates.sort((a, b) => _distanceMeters(lat, lng, a.device.lat, a.device.lng)
        .compareTo(_distanceMeters(lat, lng, b.device.lat, b.device.lng)));

    final devices = _keepRealPlaces(candidates);

    final result = List<SmartDevice>.unmodifiable([
      ..._take(devices, DeviceType.pharmacy, maxPharmacies),
      ..._take(devices, DeviceType.hospital, maxHospitals),
    ]);
    _cache = _CachedSearch(lat, lng, radiusMeters, result);
    return result;
  }

  /// Descarta o que não é um estabelecimento próprio.
  ///
  /// O OpenStreetMap marca cada pavilhão de um complexo hospitalar como
  /// `amenity=hospital` com `building=yes` — era assim que o mapa acabava
  /// mostrando "Departamento de Cirurgia" em vez da Santa Casa. Também é comum
  /// o mesmo hospital aparecer duas vezes, como nó e como polígono.
  List<SmartDevice> _keepRealPlaces(List<_Candidate> candidates) {
    final kept = <_Candidate>[];

    for (final candidate in candidates) {
      if (_isAnnex(candidate, candidates)) continue;
      if (_isDuplicate(candidate, kept)) continue;
      kept.add(candidate);
    }

    return kept.map((c) => c.device).toList();
  }

  /// Prédio dentro de um complexo hospitalar que já está na lista por inteiro.
  bool _isAnnex(_Candidate candidate, List<_Candidate> all) {
    if (!candidate.isBuilding) return false;
    if (candidate.device.type != DeviceType.hospital) return false;

    return all.any((other) =>
        !other.isBuilding &&
        other.device.type == DeviceType.hospital &&
        _distanceBetween(candidate.device, other.device) < _annexRadiusMeters);
  }

  bool _isDuplicate(_Candidate candidate, List<_Candidate> kept) {
    final radius = candidate.device.type == DeviceType.hospital
        ? _hospitalDuplicateRadiusMeters
        : _pharmacyDuplicateRadiusMeters;

    return kept.any((other) =>
        other.device.type == candidate.device.type &&
        _sameName(other.device.name, candidate.device.name) &&
        _distanceBetween(candidate.device, other.device) < radius);
  }

  /// "Santa casa" e "Santa Casa de São Paulo" são a mesma instituição.
  bool _sameName(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    return x.contains(y) || y.contains(x);
  }

  Iterable<SmartDevice> _take(
    List<SmartDevice> devices,
    DeviceType type,
    int quota,
  ) =>
      devices.where((d) => d.type == type).take(quota);

  _Candidate? _toCandidate(dynamic element) {
    if (element is! Map<String, dynamic>) return null;

    final tags = element['tags'];
    if (tags is! Map<String, dynamic>) return null;

    final name = tags['name'] as String?;
    if (name == null || name.isEmpty) return null;

    final type = switch (tags['amenity']) {
      'pharmacy' => DeviceType.pharmacy,
      'hospital' => DeviceType.hospital,
      _ => null,
    };
    if (type == null) return null;

    // Nós trazem lat/lon direto; vias e relações vêm com o centroide em `center`.
    final center = element['center'];
    final source = center is Map<String, dynamic> ? center : element;
    final lat = (source['lat'] as num?)?.toDouble();
    final lng = (source['lon'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return _Candidate(
      SmartDevice(
        id: '${element['type']}/${element['id']}',
        name: name,
        type: type,
        lat: lat,
        lng: lng,
        status: _describe(tags, type),
      ),
      isBuilding: tags['building'] != null,
    );
  }

  /// Monta a linha de apoio do card com o que o OpenStreetMap souber informar.
  String? _describe(Map<String, dynamic> tags, DeviceType type) {
    final parts = <String>[];

    final street = tags['addr:street'] as String?;
    if (street != null) {
      final number = tags['addr:housenumber'] as String?;
      parts.add(number == null ? street : '$street, $number');
    }

    if (tags['opening_hours'] == '24/7') {
      parts.add('24h');
    } else if (type == DeviceType.hospital && tags['emergency'] == 'yes') {
      parts.add('Emergência');
    }

    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Ponto vindo da Overpass junto com o que decide se ele entra no mapa.
class _Candidate {
  const _Candidate(this.device, {required this.isBuilding});

  final SmartDevice device;

  /// `building=*` distingue o pavilhão do complexo hospitalar inteiro.
  final bool isBuilding;
}

double _distanceBetween(SmartDevice a, SmartDevice b) =>
    _distanceMeters(a.lat, a.lng, b.lat, b.lng);

class _CachedSearch {
  _CachedSearch(this.lat, this.lng, this.radiusMeters, this.devices)
      : fetchedAt = DateTime.now();

  final double lat;
  final double lng;
  final int radiusMeters;
  final List<SmartDevice> devices;
  final DateTime fetchedAt;

  /// Reaproveita a busca quando o novo centro caiu bem dentro da área anterior.
  bool covers(double newLat, double newLng, int newRadius) {
    if (newRadius > radiusMeters) return false;
    if (DateTime.now().difference(fetchedAt) > OverpassDataSource.cacheTtl) {
      return false;
    }
    return _distanceMeters(lat, lng, newLat, newLng) < radiusMeters / 4;
  }
}

/// Haversine — precisão de sobra para ordenar pontos dentro de poucos km.
double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) *
          math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double degrees) => degrees * math.pi / 180;
