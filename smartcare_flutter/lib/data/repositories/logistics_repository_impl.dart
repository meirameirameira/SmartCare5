import '../../core/error/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/demo_catalog.dart';
import '../datasources/remote/smarthas_api_datasource.dart';

/// Repositório da camada AI Logistics Extension em modo demonstração:
/// entrega de medicamentos e visita domiciliar servidas pelo catálogo local.
///
/// Usado quando o back-end não está configurado. Com a API no ar o injetor
/// escolhe o [ApiDeliveryRepository].
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

/// Repositório da camada AI Logistics Extension servido pela API Smart HAS.
///
/// O pedido em acompanhamento, a trilha de status e a mensagem proativa da IA
/// vêm de `GET /patients/{id}/deliveries`, os mesmos dados que o painel
/// administrativo exibe — app e painel nunca divergem na banca.
///
/// A visita domiciliar continua vindo do catálogo local: a API ainda não expõe
/// a agenda de home care, e isso está declarado aqui em vez de escondido.
class ApiDeliveryRepository implements DeliveryRepository {
  ApiDeliveryRepository(this.api);

  final SmartHasApiDataSource api;

  @override
  Future<Result<DeliveryOrder>> loadActiveOrder() => Result.guard(() async {
        final pedidos = await api.fetchDeliveries();
        if (pedidos.isEmpty) {
          throw const ServerFailure(404, detail: 'Nenhum pedido em andamento.');
        }

        // O pedido em acompanhamento é o mais avançado que ainda não terminou;
        // não havendo nenhum ativo, mostra o último desfecho conhecido.
        final ativos = pedidos
            .where((p) =>
                p.status != DeliveryStatus.delivered &&
                p.status != DeliveryStatus.cancelled)
            .toList();

        if (ativos.isEmpty) return pedidos.first;
        ativos.sort((a, b) => b.currentStep.compareTo(a.currentStep));
        return ativos.first;
      });

  @override
  Future<Result<HomeCareVisit>> loadNextVisit() => Result.guard(() async {
        return DemoCatalog.nextVisit;
      });

  @override
  Future<Result<DeliveryOrder>> confirmDelivery(String orderId) =>
      Result.guard(() async {
        // O servidor valida a transição: um pedido que ainda não saiu para
        // rota não pode ser confirmado, e a recusa chega como 422.
        return api.changeDeliveryStatus(orderId, DeliveryStatus.delivered);
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
