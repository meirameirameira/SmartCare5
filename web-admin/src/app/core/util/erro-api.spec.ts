import { HttpErrorResponse } from '@angular/common/http';

import { errosDeCampo, mensagemDeErro } from './erro-api';

describe('traducao dos erros da API', () => {
  it('usa a mensagem do envelope devolvido pelo back-end', () => {
    const erro = new HttpErrorResponse({
      status: 422,
      error: { status: 422, message: 'Transicao invalida.' },
    });

    expect(mensagemDeErro(erro)).toBe('Transicao invalida.');
  });

  it('avisa que a API esta fora do ar quando o status e 0', () => {
    const erro = new HttpErrorResponse({ status: 0 });

    expect(mensagemDeErro(erro)).toContain('back-end esta no ar');
  });

  it('cai para uma mensagem generica quando o erro nao vem da API', () => {
    expect(mensagemDeErro(new Error('boom'))).toBe(
      'Ocorreu um erro inesperado.',
    );
  });

  it('indexa os erros de validacao por campo', () => {
    const erro = new HttpErrorResponse({
      status: 400,
      error: {
        fieldErrors: [
          { field: 'name', message: 'obrigatorio' },
          { field: 'age', message: 'deve ser positivo' },
        ],
      },
    });

    expect(errosDeCampo(erro)).toEqual({
      name: 'obrigatorio',
      age: 'deve ser positivo',
    });
  });
});
