import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { AuthService } from './core/services/auth.service';

/** Casca do painel: cabecalho de navegacao e area de conteudo roteada. */
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  private readonly router = inject(Router);
  readonly auth = inject(AuthService);

  /** O cabecalho nao aparece na tela de acesso. */
  get mostrarCabecalho(): boolean {
    return this.auth.autenticado && !this.router.url.startsWith('/login');
  }

  sair(): void {
    this.auth.sair();
  }
}
