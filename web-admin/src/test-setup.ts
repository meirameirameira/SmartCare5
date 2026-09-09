/**
 * Preparacao do ambiente de testes.
 *
 * O runner executa as specs em jsdom sem uma URL de origem definida, e nesse
 * modo o jsdom nao expoe `localStorage` (origem opaca). Como a sessao do painel
 * e guardada ali, os testes precisam de um armazenamento equivalente.
 *
 * O substituto abaixo tem o mesmo comportamento observavel do `localStorage` do
 * navegador para o que o painel usa: gravar, ler, remover e limpar.
 */
class ArmazenamentoEmMemoria implements Storage {
  private readonly dados = new Map<string, string>();

  get length(): number {
    return this.dados.size;
  }

  clear(): void {
    this.dados.clear();
  }

  getItem(chave: string): string | null {
    return this.dados.has(chave) ? this.dados.get(chave)! : null;
  }

  key(indice: number): string | null {
    return [...this.dados.keys()][indice] ?? null;
  }

  removeItem(chave: string): void {
    this.dados.delete(chave);
  }

  setItem(chave: string, valor: string): void {
    this.dados.set(chave, String(valor));
  }
}

for (const nome of ['localStorage', 'sessionStorage'] as const) {
  if (!(nome in globalThis) || (globalThis as Record<string, unknown>)[nome] == null) {
    const armazenamento = new ArmazenamentoEmMemoria();
    Object.defineProperty(globalThis, nome, {
      value: armazenamento,
      configurable: true,
    });
    if (typeof window !== 'undefined') {
      Object.defineProperty(window, nome, {
        value: armazenamento,
        configurable: true,
      });
    }
  }
}
