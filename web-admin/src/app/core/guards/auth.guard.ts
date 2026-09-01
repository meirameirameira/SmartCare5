import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from '../services/auth.service';

/** Impede o acesso as telas internas sem uma sessao valida. */
export const authGuard: CanActivateFn = (_rota, estado) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.autenticado) {
    return true;
  }

  return router.createUrlTree(['/login'], {
    queryParams: { redirecionar: estado.url },
  });
};
