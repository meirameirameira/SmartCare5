import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Alerta, Paciente, PacienteRequest } from '../models/api-models';

/** Acesso aos prontuarios e aos alertas de cada paciente. */
@Injectable({ providedIn: 'root' })
export class PatientService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/api/v1`;

  listar(busca = '', limite = 30): Observable<Paciente[]> {
    let params = new HttpParams().set('limit', limite);
    if (busca.trim()) {
      params = params.set('search', busca.trim());
    }
    return this.http.get<Paciente[]>(`${this.base}/patients`, { params });
  }

  buscarPorId(id: number): Observable<Paciente> {
    return this.http.get<Paciente>(`${this.base}/patients/${id}`);
  }

  criar(dados: PacienteRequest): Observable<Paciente> {
    return this.http.post<Paciente>(`${this.base}/patients`, dados);
  }

  atualizar(id: number, dados: PacienteRequest): Observable<Paciente> {
    return this.http.put<Paciente>(`${this.base}/patients/${id}`, dados);
  }

  remover(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/patients/${id}`);
  }

  alertasAbertos(pacienteId: number): Observable<Alerta[]> {
    const params = new HttpParams().set('onlyOpen', true);
    return this.http.get<Alerta[]>(
      `${this.base}/patients/${pacienteId}/alerts`,
      { params },
    );
  }
}
