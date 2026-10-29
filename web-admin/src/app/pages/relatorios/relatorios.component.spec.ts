import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { RelatorioPaciente } from '../../core/models/api-models';
import { RelatoriosComponent } from './relatorios.component';

function relatorio(
  patientId: number,
  patientName: string,
  latestScore: number | null,
  urgentAlerts = 0,
): RelatorioPaciente {
  return {
    patientId,
    patientName,
    periodDays: 30,
    generatedAt: '2026-10-02T17:30:00Z',
    readings: 180,
    averages: {
      heartRate: 74,
      spO2: 97.8,
      glucose: 108,
      systolic: 119,
      diastolic: 78,
      temperature: 36.6,
    },
    latestScore,
    averageScore: latestScore,
    riskLevel: 'BOM',
    glucoseTimeInRange: 76.5,
    openAlerts: urgentAlerts,
    urgentAlerts,
    alertsInPeriod: urgentAlerts,
    deliveriesTotal: 2,
    deliveriesDelivered: 1,
    summary: `${patientName}, 22 anos | Score atual: ${latestScore}/100 - BOM`,
    engine: 'ORACLE_PLSQL',
  };
}

describe('RelatoriosComponent', () => {
  let fixture: ComponentFixture<RelatoriosComponent>;
  let componente: RelatoriosComponent;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.setItem('smarthas.admin.token', 'jwt-de-teste');
    TestBed.configureTestingModule({
      imports: [RelatoriosComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
      ],
    });
    fixture = TestBed.createComponent(RelatoriosComponent);
    componente = fixture.componentInstance;
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => localStorage.clear());

  it('ao abrir, dispara a consolidacao no banco para o periodo padrao', () => {
    fixture.detectChanges();

    const chamada = http.expectOne((r) =>
      r.url.endsWith('/api/v1/reports/consolidation'),
    );
    expect(chamada.request.method).toBe('POST');
    expect(chamada.request.params.get('periodDays')).toBe('30');

    chamada.flush({
      engine: 'ORACLE_PLSQL',
      periodDays: 30,
      processed: 2,
      reports: [relatorio(2, 'Joao Silva', 41, 1), relatorio(1, 'Felipe Meira', 92)],
    });

    expect(componente.carregando).toBe(false);
    expect(componente.motor).toContain('Oracle PL/SQL');
    expect(componente.emRisco).toBe(1);
    http.verify();
  });

  it('reprocessar mantem o paciente selecionado com os dados novos', () => {
    componente.selecionado = relatorio(1, 'Felipe Meira', 80);
    componente.periodo = 7;

    componente.consolidar();
    http
      .expectOne((r) => r.params.get('periodDays') === '7')
      .flush({
        engine: 'JAVA',
        periodDays: 7,
        processed: 1,
        reports: [relatorio(1, 'Felipe Meira', 95)],
      });

    expect(componente.selecionado?.latestScore).toBe(95);
    expect(componente.motor).toContain('Java');
  });

  it('erro de regra devolvido pela procedure vira mensagem para o operador', () => {
    componente.consolidar();

    http.expectOne((r) => r.url.endsWith('/api/v1/reports/consolidation')).flush(
      { status: 422, message: 'Periodo invalido: informe entre 1 e 365 dias.' },
      { status: 422, statusText: 'Unprocessable Entity' },
    );

    expect(componente.erro).toBe('Periodo invalido: informe entre 1 e 365 dias.');
    expect(componente.carregando).toBe(false);
  });

  it('classifica a etiqueta de score pelas mesmas faixas do app', () => {
    expect(componente.classeNivel(relatorio(1, 'A', 92))).toBe('entregue');
    expect(componente.classeNivel(relatorio(1, 'A', 70))).toBe('rota');
    expect(componente.classeNivel(relatorio(1, 'A', 41))).toBe('cancelado');
    expect(componente.classeNivel(relatorio(1, 'A', null))).toBe('aguardando');
  });
});
