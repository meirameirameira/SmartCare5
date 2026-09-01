import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

import { AuthService } from '../services/auth.service';

/**
 * Anexa o token JWT a todas as chamadas da API e trata o 401 em um so lugar.
 *
 * Nenhum componente monta cabecalho de autenticacao manualmente — a mesma
 * decisao tomada no aplicativo Flutter, onde a sessao cuida do cabecalho.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.token;

  const requisicao =
    token && !req.url.includes('/auth/login')
      ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
      : req;

  return next(requisicao).pipe(
    catchError((erro: HttpErrorResponse) => {
      // Token expirado ou revogado: encerra a sessao e volta para o acesso.
      if (erro.status === 401 && !req.url.includes('/auth/login')) {
        auth.sair();
      }
      return throwError(() => erro);
    }),
  );
};
