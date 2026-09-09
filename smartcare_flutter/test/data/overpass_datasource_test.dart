import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/network/api_client.dart';
import 'package:smartcare_flutter/data/datasources/remote/overpass_datasource.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';

/// Overpass API simulada em um servidor local.
///
/// Reproduz o formato real da resposta: nós com `lat`/`lon` e vias com o
/// centroide em `center`.
class _FakeOverpassServer {
  late HttpServer _server;

  final List<String> queries = [];
  int failNext = 0;

  /// Quando definido, substitui a resposta padrão do servidor.
  List<Map<String, dynamic>>? elementsOverride;

  String get url => 'http://${_server.address.host}:${_server.port}/api/interpreter';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      queries.add(request.uri.queryParameters['data'] ?? '');

      if (failNext > 0) {
        failNext--;
        request.response.statusCode = 504;
        await request.response.close();
        return;
      }

      final override = elementsOverride;
      if (override != null) {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'elements': override}));
        await request.response.close();
        return;
      }

      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': -23.5600,
              'lon': -46.6400,
              'tags': {
                'amenity': 'pharmacy',
                'name': 'Farmácia Longe',
                'addr:street': 'Rua B',
                'addr:housenumber': '20',
              },
            },
            {
              'type': 'node',
              'id': 2,
              'lat': -23.5510,
              'lon': -46.6340,
              'tags': {
                'amenity': 'pharmacy',
                'name': 'Farmácia Perto',
                'opening_hours': '24/7',
              },
            },
            {
              'type': 'way',
              'id': 3,
              'center': {'lat': -23.5520, 'lon': -46.6350},
              'tags': {
                'amenity': 'hospital',
                'name': 'Hospital Central',
                'emergency': 'yes',
              },
            },
            // Sem nome: não vira marcador, ninguém saberia o que é.
            {
              'type': 'node',
              'id': 4,
              'lat': -23.5511,
              'lon': -46.6341,
              'tags': {'amenity': 'pharmacy'},
            },
            // Tipo fora do escopo do mapa.
            {
              'type': 'node',
              'id': 5,
              'lat': -23.5512,
              'lon': -46.6342,
              'tags': {'amenity': 'cafe', 'name': 'Café'},
            },
          ],
        }));
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late _FakeOverpassServer server;
  late OverpassDataSource datasource;

  setUp(() async {
    server = _FakeOverpassServer();
    await server.start();
    datasource = OverpassDataSource(ApiClient(maxRetries: 0), endpoint: server.url);
  });

  tearDown(() => server.stop());

  test('converte a resposta do OpenStreetMap em pontos de atendimento', () async {
    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    // Agrupado por tipo e, dentro de cada grupo, do mais perto para o mais longe.
    expect(devices.map((d) => d.name), [
      'Farmácia Perto',
      'Farmácia Longe',
      'Hospital Central',
    ]);
  });

  test('descarta elementos sem nome ou de outro tipo', () async {
    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    expect(devices, hasLength(3));
    expect(devices.any((d) => d.name == 'Café'), isFalse);
  });

  test('lê o centroide de vias e relações', () async {
    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    final hospital = devices.firstWhere((d) => d.type == DeviceType.hospital);
    expect(hospital.lat, -23.5520);
    expect(hospital.lng, -46.6350);
    expect(hospital.status, 'Emergência');
  });

  test('monta o endereço e o aviso de 24h a partir das tags', () async {
    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    expect(devices.firstWhere((d) => d.name == 'Farmácia Longe').status,
        'Rua B, 20');
    expect(devices.firstWhere((d) => d.name == 'Farmácia Perto').status, '24h');
  });

  test('reaproveita a busca anterior quando o centro quase não mudou', () async {
    await datasource.nearbyCarePoints(lat: -23.5505, lng: -46.6333);
    await datasource.nearbyCarePoints(lat: -23.5506, lng: -46.6334);

    expect(server.queries, hasLength(1));
  });

  test('refaz a busca quando o usuário se desloca', () async {
    await datasource.nearbyCarePoints(lat: -23.5505, lng: -46.6333);
    await datasource.nearbyCarePoints(lat: -22.9068, lng: -43.1729);

    expect(server.queries, hasLength(2));
  });

  test('hospitais não são engolidos por um excesso de farmácias', () async {
    // Reproduz o caso de Copacabana: dezenas de farmácias mapeadas como nós e
    // os hospitais grandes como polígonos, que a Overpass devolve por último.
    server.elementsOverride = [
      for (var i = 0; i < 60; i++)
        {
          'type': 'node',
          'id': 100 + i,
          'lat': -23.5505 + i * 0.0001,
          'lon': -46.6333,
          'tags': {'amenity': 'pharmacy', 'name': 'Farmácia $i'},
        },
      for (var i = 0; i < 5; i++)
        {
          'type': 'way',
          'id': 900 + i,
          'center': {'lat': -23.5505, 'lon': -46.6333 + i * 0.001},
          'tags': {'amenity': 'hospital', 'name': 'Hospital $i'},
        },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    final hospitais = devices.where((d) => d.type == DeviceType.hospital);
    final farmacias = devices.where((d) => d.type == DeviceType.pharmacy);

    expect(hospitais, hasLength(5));
    expect(farmacias, hasLength(OverpassDataSource.maxPharmacies));
  });

  test('respeita a cota por tipo quando há hospitais demais', () async {
    server.elementsOverride = [
      for (var i = 0; i < 40; i++)
        {
          'type': 'way',
          'id': 900 + i,
          'center': {'lat': -23.5505 + i * 0.0001, 'lon': -46.6333},
          'tags': {'amenity': 'hospital', 'name': 'Hospital $i'},
        },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    expect(devices, hasLength(OverpassDataSource.maxHospitals));
  });

  test('ignora pavilhões internos de um complexo hospitalar', () async {
    // Caso real da Santa Casa: o terreno inteiro e, dentro dele, prédios
    // marcados como hospital com building=yes.
    server.elementsOverride = [
      {
        'type': 'way',
        'id': 10,
        'center': {'lat': -23.54272, 'lon': -46.65021},
        'tags': {
          'amenity': 'hospital',
          'name': 'Santa Casa de São Paulo',
          'healthcare': 'hospital',
        },
      },
      {
        'type': 'way',
        'id': 11,
        'center': {'lat': -23.54290, 'lon': -46.65040},
        'tags': {
          'amenity': 'hospital',
          'name': 'Departamento de Cirurgia',
          'building': 'yes',
        },
      },
      {
        'type': 'way',
        'id': 12,
        'center': {'lat': -23.54300, 'lon': -46.65010},
        'tags': {
          'amenity': 'hospital',
          'name': 'Departamento de Obstetrícia e Ginecologia',
          'building': 'yes',
        },
      },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5427,
      lng: -46.6502,
    );

    expect(devices.map((d) => d.name), ['Santa Casa de São Paulo']);
  });

  test('mantém o prédio isolado quando não há complexo em volta', () async {
    server.elementsOverride = [
      {
        'type': 'way',
        'id': 20,
        'center': {'lat': -23.5505, 'lon': -46.6333},
        'tags': {
          'amenity': 'hospital',
          'name': 'Hospital de Bairro',
          'building': 'yes',
        },
      },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    expect(devices.map((d) => d.name), ['Hospital de Bairro']);
  });

  test('funde o mesmo hospital mapeado como nó e como polígono', () async {
    server.elementsOverride = [
      {
        'type': 'way',
        'id': 30,
        'center': {'lat': -23.54272, 'lon': -46.65021},
        'tags': {'amenity': 'hospital', 'name': 'Santa Casa de São Paulo'},
      },
      {
        'type': 'node',
        'id': 31,
        'lat': -23.54280,
        'lon': -46.65030,
        'tags': {'amenity': 'hospital', 'name': 'Santa casa'},
      },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5427,
      lng: -46.6502,
    );

    expect(devices, hasLength(1));
  });

  test('mantém lojas distintas de uma mesma rede de farmácias', () async {
    server.elementsOverride = [
      {
        'type': 'node',
        'id': 40,
        'lat': -23.5505,
        'lon': -46.6333,
        'tags': {'amenity': 'pharmacy', 'name': 'Drogasil'},
      },
      // ~500 m adiante: outra loja, não uma duplicata.
      {
        'type': 'node',
        'id': 41,
        'lat': -23.5550,
        'lon': -46.6333,
        'tags': {'amenity': 'pharmacy', 'name': 'Drogasil'},
      },
    ];

    final devices = await datasource.nearbyCarePoints(
      lat: -23.5505,
      lng: -46.6333,
    );

    expect(devices, hasLength(2));
  });

  test('propaga a falha quando a Overpass não responde', () async {
    server.failNext = 1;

    expect(
      () => datasource.nearbyCarePoints(lat: -23.5505, lng: -46.6333),
      throwsA(isA<Exception>()),
    );
  });
}
