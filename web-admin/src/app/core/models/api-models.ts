/**
 * Contratos TypeScript espelhando os DTOs da API Smart HAS.
 *
 * Manter os tipos aqui garante que qualquer mudanca no back-end apareca como
 * erro de compilacao no painel, e nao como falha silenciosa em producao.
 */

export type Papel = 'PATIENT' | 'PROFESSIONAL' | 'ADMIN';

export interface Usuario {
  id: number;
  email: string;
  name: string;
  role: Papel;
  patientId: number | null;
}

export interface RespostaLogin {
  accessToken: string;
  tokenType: string;
  expiresInMinutes: number;
  user: Usuario;
}

export interface Paciente {
  id: number;
  name: string;
  initials: string;
  age: number;
  conditions: string[];
  wearableConnected: boolean;
  updatedAt: string;
}

/** Corpo aceito por POST e PUT /api/v1/patients. */
export interface PacienteRequest {
  name: string;
  age: number | null;
  conditions: string[];
  wearableConnected: boolean;
}

export type StatusEntrega =
  | 'CONFIRMED'
  | 'PREPARING'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'CANCELLED';

export interface EtapaEntrega {
  label: string;
  done: boolean;
  current: boolean;
}

export interface Entrega {
  id: number;
  orderCode: string;
  patientId: number;
  patientName: string;
  description: string;
  pharmacyName: string;
  status: StatusEntrega;
  currentStep: number;
  steps: EtapaEntrega[];
  distanceKm: number;
  etaMinutes: number | null;
  proactiveMessage: string | null;
  updatedAt: string;
}

export type TipoAlerta = 'URGENT' | 'WARNING' | 'INFO' | 'OK';

export interface Alerta {
  id: number;
  patientId: number;
  type: TipoAlerta;
  title: string;
  description: string;
  metric: string | null;
  acknowledged: boolean;
  createdAt: string;
}

export interface VisaoGeral {
  totalPatients: number;
  openAlerts: number;
  urgentAlerts: number;
  deliveriesInTransit: number;
  deliveriesDelivered: number;
  upcomingAppointments: number;
  deliveriesByStatus: Record<string, number>;
}

/** Quem calculou o relatorio: as rotinas PL/SQL do Oracle ou o motor Java. */
export type MotorRelatorio = 'ORACLE_PLSQL' | 'JAVA';

export interface MediasVitais {
  heartRate: number | null;
  spO2: number | null;
  glucose: number | null;
  systolic: number | null;
  diastolic: number | null;
  temperature: number | null;
}

/** Linha de PATIENT_REPORT, gravada pela PRC_CONSOLIDAR_RELATORIO. */
export interface RelatorioPaciente {
  patientId: number;
  patientName: string;
  periodDays: number;
  generatedAt: string;
  readings: number;
  averages: MediasVitais;
  latestScore: number | null;
  averageScore: number | null;
  riskLevel: string;
  glucoseTimeInRange: number | null;
  openAlerts: number;
  urgentAlerts: number;
  alertsInPeriod: number;
  deliveriesTotal: number;
  deliveriesDelivered: number;
  summary: string;
  engine: MotorRelatorio;
}

export interface Consolidacao {
  engine: MotorRelatorio;
  periodDays: number;
  processed: number;
  reports: RelatorioPaciente[];
}

/** Envelope de erro padronizado devolvido pela API. */
export interface ErroApi {
  timestamp: string;
  status: number;
  error: string;
  message: string;
  path: string;
  fieldErrors?: { field: string; message: string }[];
}
