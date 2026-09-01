import { HttpErrorResponse } from '@angular/common/http';

import { ErroApi } from '../models/api-models';

/**
 * Converte a resposta de erro da API na mensagem exibida ao operador.
 *
 * O back-end devolve sempre o mesmo envelope, o que permite tratar todas as
 * falhas em um unico lugar.
 */
export function mensagemDeErro(erro: unknown): string {
  if (!(erro instanceof HttpErrorResponse)) {
    return 'Ocorreu um erro inesperado.';
  }

  if (erro.status === 0) {
    return 'Nao foi possivel falar com a API. Verifique se o back-end esta no ar.';
  }

  const corpo = erro.error as ErroApi | null;
  if (corpo?.message) {
    return corpo.message;
  }

  return `Falha na comunicacao com a API (codigo ${erro.status}).`;
}

/** Erros por campo, quando a API responde 400 com fieldErrors. */
export function errosDeCampo(erro: unknown): Record<string, string> {
  if (!(erro instanceof HttpErrorResponse)) {
    return {};
  }
  const corpo = erro.error as ErroApi | null;
  const mapa: Record<string, string> = {};
  for (const item of corpo?.fieldErrors ?? []) {
    mapa[item.field] = item.message;
  }
  return mapa;
}
