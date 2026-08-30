import '../../domain/entities/entities.dart';
import 'local/demo_catalog.dart';
import 'remote/smarthas_api_datasource.dart';

/// Origem do prontuário exibido no app.
///
/// Assim como acontece com os sinais vitais, o repositório depende da interface
/// e o injetor decide se o dado vem do back-end Spring Boot ou do catálogo de
/// demonstração.
abstract interface class PatientDataSource {
  Future<Patient> fetch();
}

/// Prontuário fixo usado quando não há back-end configurado.
class DemoPatientDataSource implements PatientDataSource {
  const DemoPatientDataSource();

  @override
  Future<Patient> fetch() async => DemoCatalog.patient;
}

/// Prontuário lido de `GET /api/v1/patients/{id}` na API Smart HAS.
class ApiPatientDataSource implements PatientDataSource {
  ApiPatientDataSource(this._api);

  final SmartHasApiDataSource _api;

  @override
  Future<Patient> fetch() => _api.fetchPatient();
}
