import { TestBed } from '@angular/core/testing';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  UrlTree,
  provideRouter,
} from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

import { authGuard } from './auth.guard';

/** Executa o guard dentro de um contexto de injecao, como faz o Router. */
function rodarGuard(url: string) {
  return TestBed.runInInjectionContext(() =>
    authGuard(
      {} as ActivatedRouteSnapshot,
      { url } as RouterStateSnapshot,
    ),
  );
}

describe('authGuard', () => {
  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
      ],
    });
  });

  it('libera a rota quando ha sessao', () => {
    localStorage.setItem('smarthas.admin.token', 'jwt-de-teste');

    expect(rodarGuard('/entregas')).toBe(true);
  });

  it('redireciona para o login preservando o destino', () => {
    const resultado = rodarGuard('/entregas');

    expect(resultado).toBeInstanceOf(UrlTree);
    expect((resultado as UrlTree).toString()).toContain('/login');
    expect((resultado as UrlTree).toString()).toContain(
      'redirecionar=%2Fentregas',
    );
  });
});
