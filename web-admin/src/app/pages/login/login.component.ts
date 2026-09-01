import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import { AuthService } from '../../core/services/auth.service';
import { mensagemDeErro } from '../../core/util/erro-api';

/**
 * Tela de acesso ao painel.
 *
 * Usa two-way binding com [(ngModel)] nos campos e traduz o 401 da API em uma
 * mensagem clara, em vez de deixar o operador sem resposta.
 */
@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly rota = inject(ActivatedRoute);

  email = '';
  senha = '';
  entrando = false;
  erro: string | null = null;

  entrar(): void {
    if (!this.email.trim() || !this.senha) {
      this.erro = 'Informe e-mail e senha para continuar.';
      return;
    }

    this.entrando = true;
    this.erro = null;

    this.auth.entrar(this.email.trim(), this.senha).subscribe({
      next: () => {
        const destino =
          this.rota.snapshot.queryParamMap.get('redirecionar') ?? '/home';
        this.router.navigateByUrl(destino);
      },
      error: (erro) => {
        this.erro = mensagemDeErro(erro);
        this.entrando = false;
      },
    });
  }

  /** Preenche as credenciais de demonstracao para facilitar a avaliacao. */
  usarDemonstracao(): void {
    this.email = 'enfermagem@smarthas.com';
    this.senha = 'enfermagem123';
  }
}
