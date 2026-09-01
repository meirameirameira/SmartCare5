import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { VisaoGeral } from '../models/api-models';

/** Indicadores consolidados da operacao (GET /analytics/overview). */
@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly http = inject(HttpClient);

  visaoGeral(): Observable<VisaoGeral> {
    return this.http.get<VisaoGeral>(
      `${environment.apiUrl}/api/v1/analytics/overview`,
    );
  }
}
