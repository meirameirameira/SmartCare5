import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { RespostaLogin, Usuario } from '../models/api-models';

/**
 * Sessao do painel: troca credenciais por JWT e guarda o token.
 *
 * O mesmo endpoint e o mesmo token usados pelo aplicativo Flutter — a diferenca
 * e apenas o perfil de quem entra (aqui, a equipe assistencial).
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);

  private static readonly CHAVE_TOKEN = 'smarthas.admin.token';
  private static readonly CHAVE_USUARIO = 'smarthas.admin.user';

  entrar(email: string, senha: string): Observable<RespostaLogin> {
    return this.http
      .post<RespostaLogin>(`${environment.apiUrl}/api/v1/auth/login`, {
        email,
        password: senha,
      })
      .pipe(
        tap((resposta) => {
          localStorage.setItem(AuthService.CHAVE_TOKEN, resposta.accessToken);
          localStorage.setItem(
            AuthService.CHAVE_USUARIO,
            JSON.stringify(resposta.user),
          );
        }),
      );
  }

  sair(): void {
    localStorage.removeItem(AuthService.CHAVE_TOKEN);
    localStorage.removeItem(AuthService.CHAVE_USUARIO);
    this.router.navigate(['/login']);
  }

  get token(): string | null {
    return localStorage.getItem(AuthService.CHAVE_TOKEN);
  }

  get autenticado(): boolean {
    return this.token !== null;
  }

  get usuario(): Usuario | null {
    const bruto = localStorage.getItem(AuthService.CHAVE_USUARIO);
    if (!bruto) {
      return null;
    }
    try {
      return JSON.parse(bruto) as Usuario;
    } catch {
      // Dado corrompido no navegador: descarta em vez de derrubar a tela.
      localStorage.removeItem(AuthService.CHAVE_USUARIO);
      return null;
    }
  }

  /** Perfis com permissao de escrita administrativa na API. */
  get equipe(): boolean {
    const papel = this.usuario?.role;
    return papel === 'PROFESSIONAL' || papel === 'ADMIN';
  }
}
