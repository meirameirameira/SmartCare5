import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        // Rota real de destino do sair(): sem ela o Router registra um erro
        // de navegacao no console durante o teste.
        provideRouter([{ path: 'login', children: [] }]),
      ],
    });
    service = TestBed.inject(AuthService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('guarda token e usuario depois de um login bem-sucedido', () => {
    expect(service.autenticado).toBe(false);

    service.entrar('admin@smarthas.com', 'admin123').subscribe();

    const req = http.expectOne(
      'http://localhost:8080/api/v1/auth/login',
    );
    // O painel fala o contrato da API (password), nao o do formulario (senha).
    expect(req.request.body).toEqual({
      email: 'admin@smarthas.com',
      password: 'admin123',
    });

    req.flush({
      accessToken: 'jwt-de-teste',
      tokenType: 'Bearer',
      expiresInMinutes: 480,
      user: {
        id: 1,
        email: 'admin@smarthas.com',
        name: 'Administracao',
        role: 'ADMIN',
      },
    });

    expect(service.token).toBe('jwt-de-teste');
    expect(service.autenticado).toBe(true);
    expect(service.usuario?.role).toBe('ADMIN');
    expect(service.equipe).toBe(true);
  });

  it('sair limpa a sessao guardada no navegador', () => {
    localStorage.setItem('smarthas.admin.token', 'jwt-de-teste');

    service.sair();

    expect(service.token).toBeNull();
    expect(service.autenticado).toBe(false);
  });

  it('descarta um usuario corrompido em vez de derrubar a tela', () => {
    localStorage.setItem('smarthas.admin.user', '{json quebrado');

    expect(service.usuario).toBeNull();
    expect(localStorage.getItem('smarthas.admin.user')).toBeNull();
  });

  it('perfil PATIENT nao conta como equipe assistencial', () => {
    localStorage.setItem(
      'smarthas.admin.user',
      JSON.stringify({ id: 3, email: 'p@x.com', name: 'P', role: 'PATIENT' }),
    );

    expect(service.equipe).toBe(false);
  });
});
