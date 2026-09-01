import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Entrega, StatusEntrega } from '../models/api-models';

/** Camada AI Logistics Extension vista pela operacao. */
@Injectable({ providedIn: 'root' })
export class DeliveryService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/api/v1`;

  porPaciente(pacienteId: number): Observable<Entrega[]> {
    return this.http.get<Entrega[]>(
      `${this.base}/patients/${pacienteId}/deliveries`,
    );
  }

  rastrear(codigo: string): Observable<Entrega> {
    return this.http.get<Entrega>(`${this.base}/deliveries/${codigo}`);
  }

  /**
   * Avanca o pedido para o proximo estagio.
   *
   * Uma transicao invalida volta como HTTP 422 e e exibida ao operador em vez
   * de ser silenciada.
   */
  mudarStatus(
    id: number,
    status: StatusEntrega,
    mensagem?: string,
  ): Observable<Entrega> {
    return this.http.patch<Entrega>(`${this.base}/deliveries/${id}/status`, {
      status,
      proactiveMessage: mensagem ?? null,
    });
  }
}
