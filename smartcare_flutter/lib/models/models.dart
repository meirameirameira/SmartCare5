// ─── Patient ──────────────────────────────────────────────────────────────────

class Patient {
  final String id;
  final String name;
  final String initials;
  final int age;
  final List<String> conditions;
  final bool wearableConnected;
  final int notificationCount;

  const Patient({
    required this.id,
    required this.name,
    required this.initials,
    required this.age,
    this.conditions = const [],
    this.wearableConnected = true,
    this.notificationCount = 0,
  });
}

// ─── Vitals ───────────────────────────────────────────────────────────────────

class VitalReading {
  final int heartRate;
  final double spO2;
  final int glucoseLevel;
  final int bpSystolic;
  final int bpDiastolic;
  final double temperature;

  const VitalReading({
    required this.heartRate,
    required this.spO2,
    required this.glucoseLevel,
    required this.bpSystolic,
    required this.bpDiastolic,
    required this.temperature,
  });
}

enum HealthLevel { critical, low, medium, good, excellent }
enum TrendDirection { up, down, stable }

class HealthScore {
  final int score;
  final HealthLevel level;
  final String label;
  final TrendDirection trend;

  const HealthScore({
    required this.score,
    required this.level,
    required this.label,
    required this.trend,
  });
}

// ─── Alerts ───────────────────────────────────────────────────────────────────

enum AlertType { urgent, warning, info, ok }

class HealthAlert {
  final String id;
  final AlertType type;
  final String title;
  final String description;
  final String timeLabel;
  final String? actionLabel;

  const HealthAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timeLabel,
    this.actionLabel,
  });
}

// ─── Delivery ─────────────────────────────────────────────────────────────────

enum DeliveryStatus { confirmed, preparing, inTransit, delivered, cancelled }

class DeliveryOrder {
  final String id;
  final String orderCode;
  final String description;
  final String pharmacyName;
  final DeliveryStatus status;
  final int currentStep;
  final String etaFrom;
  final String etaTo;
  final double distanceKm;
  final String? proactiveMessage;
  final int? minutesAway;

  const DeliveryOrder({
    required this.id,
    required this.orderCode,
    required this.description,
    required this.pharmacyName,
    required this.status,
    required this.currentStep,
    required this.etaFrom,
    required this.etaTo,
    required this.distanceKm,
    this.proactiveMessage,
    this.minutesAway,
  });

  List<DeliveryStep> get steps {
    const labels = ['Confirmado', 'Separado', 'Em rota', 'Entregue'];
    return List.generate(labels.length, (i) => DeliveryStep(
      label: labels[i],
      done: i < currentStep,
      current: i == currentStep,
    ));
  }
}

class DeliveryStep {
  final String label;
  final bool done;
  final bool current;
  const DeliveryStep({required this.label, required this.done, required this.current});
}

class HomeCareVisit {
  final String id;
  final String professionalName;
  final String specialty;
  final String description;
  final String scheduledDateTime;
  final int estimatedMinutes;
  final int confidencePercent;

  const HomeCareVisit({
    required this.id,
    required this.professionalName,
    required this.specialty,
    required this.description,
    required this.scheduledDateTime,
    required this.estimatedMinutes,
    required this.confidencePercent,
  });
}

// ─── Consulta ─────────────────────────────────────────────────────────────────

class Doctor {
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final String crm;
  final bool available;

  const Doctor({
    required this.id,
    required this.name,
    required this.initials,
    required this.specialty,
    required this.crm,
    this.available = false,
  });
}

enum AppointmentStatus { scheduled, confirmed, active, completed, cancelled }

class Appointment {
  final String id;
  final Doctor doctor;
  final String dateTimeLabel;
  final String dateTimeShort;
  final bool isToday;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.doctor,
    required this.dateTimeLabel,
    required this.dateTimeShort,
    this.isToday = false,
    required this.status,
  });
}

class NursingQueue {
  final int queueSize;
  final int estimatedWaitMinutes;
  final bool aiUpdating;

  const NursingQueue({
    required this.queueSize,
    required this.estimatedWaitMinutes,
    this.aiUpdating = true,
  });
}

// ─── Analytics ────────────────────────────────────────────────────────────────

enum MetricColor { red, blue, amber, green }

class MetricSeries {
  final String label;
  final String currentValue;
  final String unit;
  final String trend;
  final bool trendUp;
  final List<double> weeklyData;
  final MetricColor colorType;

  const MetricSeries({
    required this.label,
    required this.currentValue,
    required this.unit,
    required this.trend,
    required this.trendUp,
    required this.weeklyData,
    required this.colorType,
  });
}

enum InsightSeverity { info, warning, critical }

class AiInsight {
  final String title;
  final String description;
  final InsightSeverity severity;

  const AiInsight({
    required this.title,
    required this.description,
    required this.severity,
  });
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

enum MessageRole { ai, user }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String timeLabel;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timeLabel,
  });
}

class QuickPrompt {
  final String label;
  final String message;
  const QuickPrompt({required this.label, required this.message});
}

// ─── Map / Devices ────────────────────────────────────────────────────────────

enum DeviceType { sensor, camera, pharmacy, hospital, user }

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  final double lat;
  final double lng;
  final bool active;
  final String? status;

  const SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.active = true,
    this.status,
  });
}
