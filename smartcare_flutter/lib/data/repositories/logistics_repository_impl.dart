import '../../core/error/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/demo_catalog.dart';

/// Repositório da camada AI Logistics Extension (entrega de medicamentos e
/// visita domiciliar). Hoje servido pelo catálogo de demonstração; ao plugar o
/// backend real basta trocar esta implementação no injetor.
class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  DeliveryOrder _order = DemoCatalog.activeOrder;

  @override
  Future<Result<DeliveryOrder>> loadActiveOrder() => Result.guard(() async {
        await Future<void>.delayed(latency);
        return _order;
      });

  @override
  Future<Result<HomeCareVisit>> loadNextVisit() => Result.guard(() async {
        await Future<void>.delayed(latency);
        return DemoCatalog.nextVisit;
      });

  @override
  Future<Result<DeliveryOrder>> confirmDelivery(String orderId) =>
      Result.guard(() async {
        if (orderId != _order.id) {
          throw const ServerFailure(404, detail: 'Pedido não encontrado.');
        }
        _order = _order.copyWith(
          status: DeliveryStatus.delivered,
          currentStep: 3,
          proactiveMessage: '✅ Entrega confirmada pelo paciente.',
          minutesAway: 0,
        );
        return _order;
      });
}

/// Repositório de teleconsulta e fila de enfermagem.
class ConsultaRepositoryImpl implements ConsultaRepository {
  ConsultaRepositoryImpl({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<Result<Appointment>> loadNextAppointment() => Result.guard(() async {
        await Future<void>.delayed(latency);
        return DemoCatalog.nextAppointment;
      });

  @override
  Future<Result<List<Doctor>>> loadAvailableDoctors() => Result.guard(() async {
        await Future<void>.delayed(latency);
        return DemoCatalog.availableDoctors;
      });

  @override
  Future<Result<NursingQueue>> loadNursingQueue() => Result.guard(() async {
        await Future<void>.delayed(latency);
        return DemoCatalog.nursingQueue;
      });
}
