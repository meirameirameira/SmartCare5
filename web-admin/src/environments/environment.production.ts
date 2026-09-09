/**
 * Configuracao usada por `npm run build` (configuracao production).
 *
 * Em producao o painel e servido pelo mesmo host da API (atras de um proxy
 * reverso), entao `apiUrl` fica vazio e as chamadas saem relativas
 * (`/api/v1/...`). Assim o artefato de build nao carrega nenhum endereco de
 * maquina de desenvolvimento.
 */
export const environment = {
  production: true,
  apiUrl: '',
};
