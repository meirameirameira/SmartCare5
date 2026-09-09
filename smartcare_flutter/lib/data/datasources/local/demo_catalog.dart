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
    pharmacyName: 'Droga Raia — Praça da Sé',
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

  /// Farmacias e hospitais reais do centro de Sao Paulo. Coordenadas e nomes
  /// extraidos do OpenStreetMap, a mesma fonte dos tiles do mapa, para que os
  /// marcadores caiam exatamente sobre os estabelecimentos desenhados.
  static const devices = [
    SmartDevice(
      id: 'f1',
      name: 'Droga Raia',
      type: DeviceType.pharmacy,
      lat: -23.55025,
      lng: -46.63428,
      status: 'Praça da Sé, 152 · pedido em rota',
    ),
    SmartDevice(
      id: 'f2',
      name: 'Drogaria SP',
      type: DeviceType.pharmacy,
      lat: -23.55176,
      lng: -46.63422,
      status: 'Praça da Sé, 415',
    ),
    SmartDevice(
      id: 'f3',
      name: 'Farma Conde',
      type: DeviceType.pharmacy,
      lat: -23.55146,
      lng: -46.63517,
      status: 'Praça Doutor João Mendes, 19',
    ),
    SmartDevice(
      id: 'f4',
      name: 'Ultrafarma Popular',
      type: DeviceType.pharmacy,
      lat: -23.55477,
      lng: -46.63442,
      status: 'Rua da Glória, 174',
    ),
    SmartDevice(
      id: 'f5',
      name: 'Drogaria São Paulo',
      type: DeviceType.pharmacy,
      lat: -23.55994,
      lng: -46.63811,
      status: 'Avenida da Liberdade, 840 · 24h',
    ),
    SmartDevice(
      id: 'h1',
      name: 'Santa Casa de São Paulo',
      type: DeviceType.hospital,
      lat: -23.54272,
      lng: -46.65021,
      status: 'Pronto-socorro',
    ),
    SmartDevice(
      id: 'h2',
      name: 'Hospital A.C. Camargo Cancer Center',
      type: DeviceType.hospital,
      lat: -23.56544,
      lng: -46.63515,
      status: 'Referência oncológica',
    ),
    SmartDevice(
      id: 'h3',
      name: 'Hospital Beneficência Portuguesa',
      type: DeviceType.hospital,
      lat: -23.56739,
      lng: -46.64154,
      status: 'Pronto-socorro',
    ),
    SmartDevice(
      id: 'h4',
      name: 'Hospital Sírio-Libanês',
      type: DeviceType.hospital,
      lat: -23.55746,
      lng: -46.65377,
      status: 'Referência',
    ),
    SmartDevice(
      id: 'h5',
      name: 'Hospital das Clínicas',
      type: DeviceType.hospital,
      lat: -23.55702,
      lng: -46.66993,
      status: 'Referência · emergência 24h',
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
