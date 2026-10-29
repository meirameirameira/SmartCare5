import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { Consolidacao, RelatorioPaciente } from '../../core/models/api-models';
import { ReportService } from '../../core/services/report.service';
import { mensagemDeErro } from '../../core/util/erro-api';

/**
 * Relatorio clinico e de consumo de todos os pacientes.
 *
 * Cada consolidacao roda dentro do banco: a tela so dispara o processamento
 * e exibe o snapshot que a procedure gravou.
 */
@Component({
  selector: 'app-relatorios',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './relatorios.component.html',
  styleUrl: './relatorios.component.css',
})
export class RelatoriosComponent implements OnInit {
  private readonly reports = inject(ReportService);

  readonly periodos = [7, 30, 90];
  periodo = 30;

  consolidacao: Consolidacao | null = null;
  selecionado: RelatorioPaciente | null = null;
  carregando = false;
  erro: string | null = null;

  ngOnInit(): void {
    this.consolidar();
  }

  consolidar(): void {
    this.carregando = true;
    this.erro = null;

    this.reports.consolidar(this.periodo).subscribe({
      next: (resultado) => {
        this.consolidacao = resultado;
        // Mantem o paciente aberto no detalhe apos reprocessar.
        const id = this.selecionado?.patientId;
        this.selecionado =
          resultado.reports.find((r) => r.patientId === id) ?? null;
        this.carregando = false;
      },
      error: (erro) => {
        this.erro = mensagemDeErro(erro);
        this.carregando = false;
      },
    });
  }

  get motor(): string {
    return this.consolidacao?.engine === 'ORACLE_PLSQL'
      ? 'Oracle PL/SQL (PRC_CONSOLIDAR_RELATORIO)'
      : 'Motor Java da API (banco H2)';
  }

  /** Pacientes que pedem atencao: score abaixo de 60 ou alerta urgente. */
  get emRisco(): number {
    return (this.consolidacao?.reports ?? []).filter(
      (r) => (r.latestScore ?? 100) < 60 || r.urgentAlerts > 0,
    ).length;
  }

  classeNivel(r: RelatorioPaciente): string {
    if (r.latestScore === null) return 'aguardando';
    if (r.latestScore < 60) return 'cancelado';
    if (r.latestScore < 75) return 'rota';
    return 'entregue';
  }

  linhasResumo(r: RelatorioPaciente): string[] {
    return r.summary.split(' | ');
  }
}
