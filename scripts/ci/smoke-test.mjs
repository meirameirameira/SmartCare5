// =============================================================================
// Smart HAS - smoke test da API publicada sobre o Oracle
//
// Exercita o caminho completo REST -> Spring -> JDBC -> packages PL/SQL ->
// triggers e termina com codigo 1 na primeira verificacao que nao passar.
//
// Uso: node scripts/ci/smoke-test.mjs [URL_BASE]   (default http://localhost:8080)
// Requer Node 18+ (fetch nativo) - disponivel no runner do GitHub Actions.
// =============================================================================
const BASE_URL = process.argv[2] ?? 'http://localhost:8080';
let token;
let passou = 0;

function ok(mensagem) {
  passou += 1;
  console.log(`[OK]    ${mensagem}`);
}

function verificar(condicao, mensagem, detalhe) {
  if (!condicao) {
    console.log(`[FALHA] ${mensagem}${detalhe ? ` - ${detalhe}` : ''}`);
    process.exit(1);
  }
  ok(mensagem);
}

async function chamada(metodo, caminho, corpo) {
  const resposta = await fetch(BASE_URL + caminho, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  const texto = await resposta.text();
  let json = null;
  try {
    json = JSON.parse(texto);
  } catch {
    // corpo vazio ou texto puro
  }
  return { status: resposta.status, json, texto };
}

console.log(`== Smoke test em ${BASE_URL}`);

const saude = await chamada('GET', '/actuator/health');
verificar(saude.status === 200 && saude.json?.status === 'UP', 'actuator/health = UP', saude.texto);

const login = await chamada('POST', '/api/v1/auth/login', { email: 'admin@smarthas.com', password: 'admin123' });
token = login.json?.accessToken;
verificar(login.status === 200 && token, 'login JWT do administrador', `HTTP ${login.status}`);

const pacientes = await chamada('GET', '/api/v1/patients?search=Felipe');
const paciente = pacientes.json?.find?.((p) => p.name === 'Felipe Meira');
verificar(pacientes.status === 200 && paciente, `pacientes lidos do Oracle (Felipe Meira = id ${paciente?.id})`, pacientes.texto);

const antes = await chamada('GET', `/api/v1/patients/${paciente.id}/alerts?onlyOpen=true&limit=100`);

// Leitura critica: a API grava via JPA e chama PKG_MONITORAMENTO.PRC_REGISTRAR_ALERTAS_LEITURA.
const leitura = await chamada('POST', `/api/v1/patients/${paciente.id}/vitals`, {
  heartRate: 124, spO2: 89.5, glucoseLevel: 230, bpSystolic: 150, bpDiastolic: 95, temperature: 38.2,
});
verificar(leitura.status === 201, 'leitura critica gravada (HTTP 201)', leitura.texto);

const alertas = await chamada('GET', `/api/v1/patients/${paciente.id}/alerts?onlyOpen=true&limit=100`);
const urgentes = (alertas.json ?? []).filter((a) => a.type === 'URGENT').length;
verificar(alertas.status === 200 && urgentes >= 1 && alertas.json.length >= antes.json.length,
  `${urgentes} alerta(s) urgente(s) aberto(s) pelo package PL/SQL`, alertas.texto);

const relatorio = await chamada('GET', `/api/v1/patients/${paciente.id}/report?periodDays=30`);
verificar(relatorio.status === 200 && relatorio.json?.engine === 'ORACLE_PLSQL',
  `relatorio por PKG_RELATORIOS (score ${relatorio.json?.latestScore}, ${relatorio.json?.riskLevel})`, relatorio.texto);

const invalido = await chamada('GET', `/api/v1/patients/${paciente.id}/report?periodDays=0`);
verificar(invalido.status === 422, 'periodo invalido rejeitado pela procedure (ORA-20003 -> HTTP 422)',
  `HTTP ${invalido.status} ${invalido.texto}`);

const lote = await chamada('POST', '/api/v1/reports/consolidation?periodDays=7');
verificar(lote.status === 200, 'consolidacao em lote de todos os pacientes', lote.texto);

console.log(`== ${passou} verificacoes, 0 falha(s)`);
