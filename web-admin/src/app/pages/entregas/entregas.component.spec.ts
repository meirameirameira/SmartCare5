import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { Entrega, StatusEntrega } from '../../core/models/api-models';
import { EntregasComponent } from './entregas.component';

function entrega(
  id: number,
  orderCode: string,
  status: StatusEntrega,
  updatedAt: string,
): Entrega {
  return {
    id,
    orderCode,
    patientId: 1,
    patientName: 'Felipe Meira',
    description: 'Metformina 500mg',
    pharmacyName: 'Farmacia Leroy Health',
    status,
    currentStep: 0,
    steps: [],
    distanceKm: 3.2,
    etaMinutes: 28,
    proactiveMessage: null,
    updatedAt,
  };
}

describe('EntregasComponent', () => {
  let fixture: ComponentFixture<EntregasComponent>;
  let componente: EntregasComponent;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.setItem('smarthas.admin.token', 'jwt-de-teste');
    TestBed.configureTestingModule({
      imports: [EntregasComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
      ],
    });
    fixture = TestBed.createComponent(EntregasComponent);
    componente = fixture.componentInstance;
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => localStorage.clear());

  it('consolida os pedidos de todos os pacientes, do mais recente ao mais antigo', () => {
    fixture.detectChanges();

    http
      .expectOne((r) => r.url.endsWith('/api/v1/patients'))
      .flush([
        { id: 1, name: 'Felipe Meira' },
        { id: 2, name: 'Joao Silva' },
      ]);

    http
      .expectOne((r) => r.url.endsWith('/api/v1/patients/1/deliveries'))
      .flush([entrega(1, 'SC-2026-0412', 'IN_TRANSIT', '2026-09-01T10:00:00Z')]);
    http
      .expectOne((r) => r.url.endsWith('/api/v1/patients/2/deliveries'))
      .flush([entrega(2, 'SC-2026-0388', 'DELIVERED', '2026-09-02T10:00:00Z')]);

    expect(componente.carregando).toBe(false);
    expect(componente.entregas.map((e) => e.orderCode)).toEqual([
      'SC-2026-0388',
      'SC-2026-0412',
    ]);
    http.verify();
  });

  it('o filtro de status restringe a lista exibida', () => {
    componente.entregas = [
      entrega(1, 'SC-1', 'IN_TRANSIT', '2026-09-01T10:00:00Z'),
      entrega(2, 'SC-2', 'DELIVERED', '2026-09-01T11:00:00Z'),
    ];

    expect(componente.entregasFiltradas.length).toBe(2);

    componente.filtroStatus = 'IN_TRANSIT';
    expect(componente.entregasFiltradas.map((e) => e.orderCode)).toEqual([
      'SC-1',
    ]);
  });

  it('o proximo estagio segue o mesmo fluxo logistico do back-end', () => {
    expect(
      componente.proximoStatus(entrega(1, 'SC-1', 'CONFIRMED', '')),
    ).toBe('PREPARING');
    expect(
      componente.proximoStatus(entrega(1, 'SC-1', 'PREPARING', '')),
    ).toBe('IN_TRANSIT');
    expect(
      componente.proximoStatus(entrega(1, 'SC-1', 'IN_TRANSIT', '')),
    ).toBe('DELIVERED');
  });

  it('pedido entregue ou cancelado e terminal: nao ha proximo estagio', () => {
    expect(
      componente.proximoStatus(entrega(1, 'SC-1', 'DELIVERED', '')),
    ).toBeNull();
    expect(
      componente.proximoStatus(entrega(1, 'SC-1', 'CANCELLED', '')),
    ).toBeNull();
  });

  it('uma transicao recusada pela API vira mensagem para o operador', () => {
    const alvo = entrega(1, 'SC-2026-0412', 'IN_TRANSIT', '2026-09-01T10:00:00Z');
    componente.entregas = [alvo];

    componente.avancar(alvo);

    http.expectOne((r) => r.url.endsWith('/api/v1/deliveries/1/status')).flush(
      { status: 422, message: 'Transicao invalida.' },
      { status: 422, statusText: 'Unprocessable Entity' },
    );

    expect(componente.erro).toBe('Transicao invalida.');
    expect(componente.atualizandoId).toBeNull();
  });
});
