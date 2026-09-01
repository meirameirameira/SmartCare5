import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';

/** Composicao da aplicacao: rotas, HttpClient e interceptor de autenticacao. */
export const appConfig: ApplicationConfig = {
  providers: [
    // Deteccao de mudancas classica: os componentes usam propriedades simples
    // com data binding, e nao signals.
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([authInterceptor])),
  ],
};
