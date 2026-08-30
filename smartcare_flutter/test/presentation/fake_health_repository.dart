import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/result/result.dart';
import 'package:smartcare_flutter/data/datasources/local/demo_catalog.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/repositories/repositories.dart';

/// Repositório falso usado nos testes de provider e de widget.
///
/// Só é possível escrever este fake porque a camada de apresentação depende da
/// interface [HealthRepository], e não de um service concreto — este é o
/// ganho prático da inversão de dependência aplicada nesta fase.
class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({VitalReading? vitals}) : reading = vitals ?? stable;

  static const stable = VitalReading(
    heartRate: 72,
    spO2: 98.5,
    glucoseLevel: 104,
    bpSystolic: 118,
    bpDiastolic: 78,
    temperature: 36.6,
  );

  VitalReading reading;
  AppFailure? failure;
  bool fromCache = false;
  String? weather = '☀️ Céu limpo · 24°C · Umidade 55%';

  @override
  Future<Result<Patient>> loadPatient() async => const Ok(DemoCatalog.patient);

  @override
  Future<Result<Sourced<VitalReading>>> loadVitals() async {
    if (failure != null) return Err(failure!);
    return Ok(Sourced(reading, fromCache: fromCache, updatedAt: DateTime.now()));
  }

  @override
  Future<Result<Sourced<String>>> loadWeather() async {
    if (weather == null) return const Err(NetworkFailure());
    return Ok(Sourced(weather!, updatedAt: DateTime.now()));
  }
}
