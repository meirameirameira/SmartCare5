import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Consolidacao } from '../models/api-models';

/**
 * Relatorios consolidados no banco.
 *
 * POST /reports/consolidation dispara a procedure PRC_CONSOLIDAR_RELATORIO
 * (Angular -> REST -> Spring -> JDBC -> Oracle) para todos os pacientes.
 */
@Injectable({ providedIn: 'root' })
export class ReportService {
  private readonly http = inject(HttpClient);

  consolidar(periodDays: number): Observable<Consolidacao> {
    const params = new HttpParams().set('periodDays', periodDays);
    return this.http.post<Consolidacao>(
      `${environment.apiUrl}/api/v1/reports/consolidation`,
      null,
      { params },
    );
  }
}
