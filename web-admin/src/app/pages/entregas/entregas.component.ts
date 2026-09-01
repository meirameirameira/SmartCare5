import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { forkJoin, of, switchMap } from 'rxjs';

import { Entrega, StatusEntrega } from '../../core/models/api-models';
import { DeliveryService } from '../../core/services/delivery.service';
import { PatientService } from '../../core/services/patient.service';
import { mensagemDeErro } from '../../core/util/erro-api';

/**
 * Acompanhamento das entregas da camada AI Logistics Extension.
 *
 * A API expoe os pedidos por paciente, entao a tela carrega os prontuarios e
 * consolida os pedidos de todos eles em uma unica lista para a operacao.
 */
@Component({
  selector: 'app-entregas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './entregas.component.html',
  styleUrl: './entregas.component.css',
})
export class EntregasComponent implements OnInit {
  private readonly service = inject(DeliveryService);
  private readonly pacientes = inject(PatientService);

  entregas: Entrega[] = [];
  carregando = false;
  erro: string | null = null;
  aviso: string | null = null;
  atualizandoId: number | null = null;

  /** Filtro ligado ao <select> por [(ngModel)]. */
  filtroStatus: 'TODOS' | StatusEntrega = 'TODOS';

  readonly opcoesStatus: { valor: 'TODOS' | StatusEntrega; rotulo: string }[] = [
    { valor: 'TODOS', rotulo: 'Todos' },
    { valor: 'CONFIRMED', rotulo: 'Confirmado' },
    { valor: 'PREPARING', rotulo: 'Separado' },
    { valor: 'IN_TRANSIT', rotulo: 'Em rota' },
    { valor: 'DELIVERED', rotulo: 'Entregue' },
    { valor: 'CANCELLED', rotulo: 'Cancelado' },
  ];

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.erro = null;
    // Um aviso da acao anterior nao deve ficar na tela junto de um erro novo.
    this.aviso = null;

    this.pacientes
      .listar('', 50)
      .pipe(
        switchMap((lista) =>
          lista.length === 0
            ? of([] as Entrega[][])
            : forkJoin(lista.map((p) => this.service.porPaciente(p.id))),
        ),
      )
      .subscribe({
        next: (resultados) => {
          this.entregas = resultados
            .flat()
            .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
          this.carregando = false;
        },
        error: (erro) => {
          this.erro = mensagemDeErro(erro);
          this.carregando = false;
        },
      });
  }

  /** Lista efetivamente renderizada, ja aplicando o filtro escolhido. */
  get entregasFiltradas(): Entrega[] {
    if (this.filtroStatus === 'TODOS') {
      return this.entregas;
    }
    return this.entregas.filter((e) => e.status === this.filtroStatus);
  }

  /** Proximo estagio possivel; nulo quando o pedido ja e terminal. */
  proximoStatus(entrega: Entrega): StatusEntrega | null {
    const fluxo: StatusEntrega[] = [
      'CONFIRMED',
      'PREPARING',
      'IN_TRANSIT',
      'DELIVERED',
    ];
    const atual = fluxo.indexOf(entrega.status);
    if (atual < 0 || atual === fluxo.length - 1) {
      return null;
    }
    return fluxo[atual + 1];
  }

  avancar(entrega: Entrega): void {
    const proximo = this.proximoStatus(entrega);
    if (!proximo) {
      return;
    }

    this.atualizandoId = entrega.id;
    this.erro = null;
    this.aviso = null;

    this.service.mudarStatus(entrega.id, proximo).subscribe({
      next: (atualizada) => {
        this.entregas = this.entregas.map((e) =>
          e.id === atualizada.id ? atualizada : e,
        );
        this.aviso = `Pedido ${atualizada.orderCode} agora esta em "${this.rotulo(atualizada.status)}".`;
        this.atualizandoId = null;
      },
      error: (erro) => {
        // Transicao invalida volta como 422 e e mostrada ao operador.
        this.erro = mensagemDeErro(erro);
        this.atualizandoId = null;
      },
    });
  }

  cancelar(entrega: Entrega): void {
    this.atualizandoId = entrega.id;
    this.service
      .mudarStatus(entrega.id, 'CANCELLED', 'Cancelado pela operacao.')
      .subscribe({
        next: (atualizada) => {
          this.entregas = this.entregas.map((e) =>
            e.id === atualizada.id ? atualizada : e,
          );
          this.aviso = `Pedido ${atualizada.orderCode} cancelado.`;
          this.atualizandoId = null;
        },
        error: (erro) => {
          this.erro = mensagemDeErro(erro);
          this.atualizandoId = null;
        },
      });
  }

  rotulo(status: string): string {
    return (
      this.opcoesStatus.find((o) => o.valor === status)?.rotulo ?? status
    );
  }

  classe(status: StatusEntrega): string {
    const classes: Record<StatusEntrega, string> = {
      CONFIRMED: 'aguardando',
      PREPARING: 'aguardando',
      IN_TRANSIT: 'rota',
      DELIVERED: 'entregue',
      CANCELLED: 'cancelado',
    };
    return classes[status];
  }
}
