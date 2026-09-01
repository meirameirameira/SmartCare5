import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { VisaoGeral } from '../../core/models/api-models';
import { AnalyticsService } from '../../core/services/analytics.service';
import { AuthService } from '../../core/services/auth.service';
import { mensagemDeErro } from '../../core/util/erro-api';

interface Indicador {
  titulo: string;
  valor: number;
  detalhe?: string;
  destaque: boolean;
}

/** Visao geral da operacao, alimentada por GET /api/v1/analytics/overview. */
@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css',
})
export class HomeComponent implements OnInit {
  private readonly analytics = inject(AnalyticsService);
  private readonly auth = inject(AuthService);

  visao: VisaoGeral | null = null;
  carregando = false;
  erro: string | null = null;
  atualizadoEm: Date | null = null;

  get nome(): string {
    return this.auth.usuario?.name ?? 'equipe';
  }

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.erro = null;

    this.analytics.visaoGeral().subscribe({
      next: (visao) => {
        this.visao = visao;
        this.atualizadoEm = new Date();
        this.carregando = false;
      },
      error: (erro) => {
        this.erro = mensagemDeErro(erro);
        this.carregando = false;
      },
    });
  }

  /** Cartoes exibidos no topo, derivados da resposta da API. */
  get indicadores(): Indicador[] {
    if (!this.visao) {
      return [];
    }
    return [
      {
        titulo: 'Pacientes monitorados',
        valor: this.visao.totalPatients,
        destaque: false,
      },
      {
        titulo: 'Alertas em aberto',
        valor: this.visao.openAlerts,
        detalhe: `${this.visao.urgentAlerts} urgente(s)`,
        destaque: this.visao.urgentAlerts > 0,
      },
      {
        titulo: 'Entregas em rota',
        valor: this.visao.deliveriesInTransit,
        detalhe: `${this.visao.deliveriesDelivered} concluida(s)`,
        destaque: false,
      },
      {
        titulo: 'Consultas agendadas',
        valor: this.visao.upcomingAppointments,
        destaque: false,
      },
    ];
  }

  /** Contagem por status vinda do back-end, ja agregada no banco. */
  get statusEntregas(): { status: string; total: number }[] {
    const mapa = this.visao?.deliveriesByStatus ?? {};
    return Object.keys(mapa).map((status) => ({ status, total: mapa[status] }));
  }

  rotulo(status: string): string {
    const rotulos: Record<string, string> = {
      CONFIRMED: 'Confirmado',
      PREPARING: 'Separado',
      IN_TRANSIT: 'Em rota',
      DELIVERED: 'Entregue',
      CANCELLED: 'Cancelado',
    };
    return rotulos[status] ?? status;
  }
}
