import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { Paciente, PacienteRequest } from '../../core/models/api-models';
import { AuthService } from '../../core/services/auth.service';
import { PatientService } from '../../core/services/patient.service';
import { errosDeCampo, mensagemDeErro } from '../../core/util/erro-api';

/**
 * Gestao de prontuarios.
 *
 * Concentra o formulario funcional do painel: cadastro e edicao de pacientes
 * com two-way binding, validacao local e exibicao dos erros por campo
 * devolvidos pela API (HTTP 400 com fieldErrors).
 */
@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin.component.html',
  styleUrl: './admin.component.css',
})
export class AdminComponent implements OnInit {
  private readonly service = inject(PatientService);
  private readonly auth = inject(AuthService);

  pacientes: Paciente[] = [];
  carregando = false;
  salvando = false;
  erro: string | null = null;
  sucesso: string | null = null;
  errosCampo: Record<string, string> = {};

  /** Ligado ao campo de busca por [(ngModel)]. */
  busca = '';

  /** Registro em edicao; nulo quando o formulario esta criando. */
  editandoId: number | null = null;

  formulario: PacienteRequest & { condicoesTexto: string } = this.formularioVazio();

  get podeEditar(): boolean {
    return this.auth.equipe;
  }

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando = true;
    this.erro = null;

    this.service.listar(this.busca).subscribe({
      next: (pacientes) => {
        this.pacientes = pacientes;
        this.carregando = false;
      },
      error: (erro) => {
        this.erro = mensagemDeErro(erro);
        this.carregando = false;
      },
    });
  }

  limparBusca(): void {
    this.busca = '';
    this.carregar();
  }

  editar(paciente: Paciente): void {
    this.editandoId = paciente.id;
    this.formulario = {
      name: paciente.name,
      age: paciente.age,
      conditions: paciente.conditions,
      wearableConnected: paciente.wearableConnected,
      condicoesTexto: paciente.conditions.join(', '),
    };
    this.errosCampo = {};
    this.sucesso = null;
  }

  cancelarEdicao(): void {
    this.editandoId = null;
    this.formulario = this.formularioVazio();
    this.errosCampo = {};
  }

  salvar(): void {
    this.errosCampo = {};
    this.erro = null;
    this.sucesso = null;

    const validacao = this.validar();
    if (Object.keys(validacao).length > 0) {
      this.errosCampo = validacao;
      return;
    }

    const dados: PacienteRequest = {
      name: this.formulario.name.trim(),
      age: this.formulario.age,
      conditions: this.condicoesInformadas(),
      wearableConnected: this.formulario.wearableConnected,
    };

    this.salvando = true;

    const requisicao =
      this.editandoId === null
        ? this.service.criar(dados)
        : this.service.atualizar(this.editandoId, dados);

    requisicao.subscribe({
      next: (paciente) => {
        this.sucesso =
          this.editandoId === null
            ? `Paciente ${paciente.name} cadastrado com sucesso.`
            : `Prontuario de ${paciente.name} atualizado.`;
        this.salvando = false;
        this.cancelarEdicao();
        this.carregar();
      },
      error: (erro) => {
        // A API devolve os campos invalidos: exibimos cada um ao lado do input.
        this.errosCampo = errosDeCampo(erro);
        this.erro = mensagemDeErro(erro);
        this.salvando = false;
      },
    });
  }

  remover(paciente: Paciente): void {
    if (!confirm(`Remover o prontuario de ${paciente.name}?`)) {
      return;
    }
    this.service.remover(paciente.id).subscribe({
      next: () => {
        this.sucesso = `Prontuario de ${paciente.name} removido.`;
        this.carregar();
      },
      error: (erro) => (this.erro = mensagemDeErro(erro)),
    });
  }

  private validar(): Record<string, string> {
    const erros: Record<string, string> = {};
    if (this.formulario.name.trim().length < 3) {
      erros['name'] = 'Informe o nome completo (minimo 3 caracteres).';
    }
    if (this.formulario.age === null || this.formulario.age < 0 || this.formulario.age > 130) {
      erros['age'] = 'Informe uma idade entre 0 e 130 anos.';
    }
    return erros;
  }

  private condicoesInformadas(): string[] {
    return this.formulario.condicoesTexto
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
  }

  private formularioVazio(): PacienteRequest & { condicoesTexto: string } {
    return {
      name: '',
      age: null,
      conditions: [],
      wearableConnected: true,
      condicoesTexto: '',
    };
  }
}
