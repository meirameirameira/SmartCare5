import '../../../domain/entities/entities.dart';

/// Catálogo de dados de demonstração do piloto SmartCare 5.0.
///
/// Antes esses literais estavam espalhados dentro dos `ChangeNotifier`, o que
/// misturava fonte de dados com estado de UI. Concentrá-los aqui deixa claro o
/// que é mock e permite substituir por um backend real trocando apenas o
/// datasource injetado no repositório.
abstract final class DemoCatalog {
  static const patient = Patient(
    id: 'p001',
    name: 'Felipe Meira',
    initials: 'FM',
    age: 22,
    conditions: ['Hipertensão leve', 'Diabetes tipo 2'],
    wearableConnected: true,
    notificationCount: 3,
  );

  static const activeOrder = DeliveryOrder(
    id: 'd001',
    orderCode: '#SC-2024-0412',
    description: 'Metformina 500mg (60cp) + Losartana 50mg (30cp)',
    pharmacyName: 'Farmácia Leroy Health',
    status: DeliveryStatus.inTransit,
    currentStep: 2,
    etaFrom: '14h20',
    etaTo: '15h00',
    distanceKm: 3.2,
    proactiveMessage:
        '🤖 IA detectou trânsito na Av. Paulista — rota alternativa ativa. ETA mantido.',
    minutesAway: 28,
  );

  static const nextVisit = HomeCareVisit(
    id: 'v001',
    professionalName: 'Enf. Carla Souza',
    specialty: 'Enfermagem Home Care',
    description: 'Verificação de sinais vitais + troca de curativo',
    scheduledDateTime: 'Amanhã, 09h00',
    estimatedMinutes: 45,
    confidencePercent: 94,
  );

  static const nextAppointment = Appointment(
    id: 'ap001',
    doctor: Doctor(
      id: 'dr001',
      name: 'Dr. Ricardo Alves',
      initials: 'RA',
      specialty: 'Endocrinologia',
      crm: 'CRM/SP 87432',
    ),
    dateTimeLabel: 'Hoje, 14h30 — Teleconsulta',
    dateTimeShort: '14h30',
    isToday: true,
    status: AppointmentStatus.confirmed,
  );

  static const availableDoctors = [
    Doctor(
      id: 'dr002',
      name: 'Dra. Ana Lima',
      initials: 'AL',
      specialty: 'Clínica Geral',
      crm: 'CRM/SP 54210',
      available: true,
    ),
    Doctor(
      id: 'dr003',
      name: 'Dr. Paulo Neto',
      initials: 'PN',
      specialty: 'Cardiologia',
      crm: 'CRM/SP 33091',
    ),
  ];

  static const nursingQueue = NursingQueue(
    queueSize: 4,
    estimatedWaitMinutes: 22,
  );

  static const devices = [
    SmartDevice(
      id: 's1',
      name: 'Sensor Cardíaco — Casa',
      type: DeviceType.sensor,
      lat: -23.5505,
      lng: -46.6333,
      status: 'Online · 72 bpm',
    ),
    SmartDevice(
      id: 's2',
      name: 'Sensor Glicêmico — Sala',
      type: DeviceType.sensor,
      lat: -23.5520,
      lng: -46.6360,
      status: 'Online · 104 mg/dL',
    ),
    SmartDevice(
      id: 'c1',
      name: 'Câmera Segurança — Entrada',
      type: DeviceType.camera,
      lat: -23.5490,
      lng: -46.6310,
      status: 'Streaming ativo',
    ),
    SmartDevice(
      id: 'f1',
      name: 'Farmácia Leroy Health',
      type: DeviceType.pharmacy,
      lat: -23.5560,
      lng: -46.6410,
      status: 'Pedido em rota',
    ),
    SmartDevice(
      id: 'h1',
      name: 'Hospital das Clínicas',
      type: DeviceType.hospital,
      lat: -23.5554,
      lng: -46.6720,
      status: 'Referência',
    ),
    SmartDevice(
      id: 'h2',
      name: 'UPA Lapa',
      type: DeviceType.hospital,
      lat: -23.5250,
      lng: -46.6900,
      status: 'Urgência',
    ),
  ];

  static const insights = [
    AiInsight(
      title: 'Pico glicêmico pós-almoço',
      description:
          'Sua glicemia sobe em média 18% entre 13h e 15h. Uma caminhada leve após o almoço reduz esse pico.',
      severity: InsightSeverity.warning,
    ),
    AiInsight(
      title: 'FC em repouso ideal',
      description:
          'Frequência cardíaca de repouso média de 68 bpm — dentro do range saudável para sua faixa etária.',
      severity: InsightSeverity.info,
    ),
    AiInsight(
      title: 'Aderência medicamentosa excelente',
      description: '96% de aderência nos últimos 14 dias. Continue assim!',
      severity: InsightSeverity.info,
    ),
  ];
}
