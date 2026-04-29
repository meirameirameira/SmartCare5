package com.smarthas.smartcare.data.model

import java.time.LocalDateTime

// ─── Patient / User ───────────────────────────────────────────────────────────

data class Patient(
    val id: String,
    val name: String,
    val initials: String,
    val age: Int,
    val conditions: List<String> = emptyList(),
    val wearableConnected: Boolean = true,
    val notificationCount: Int = 0
)

// ─── Vitals ───────────────────────────────────────────────────────────────────

data class VitalReading(
    val heartRate: Int,           // bpm
    val spO2: Float,              // %
    val glucoseLevel: Int,        // mg/dL
    val bloodPressureSystolic: Int,
    val bloodPressureDiastolic: Int,
    val temperature: Float,       // °C
    val timestamp: Long = System.currentTimeMillis()
)

data class HealthScore(
    val score: Int,                // 0–100
    val level: HealthLevel,
    val label: String,
    val trend: TrendDirection
)

enum class HealthLevel { CRITICAL, LOW, MEDIUM, GOOD, EXCELLENT }
enum class TrendDirection { UP, DOWN, STABLE }

// ─── Alerts ───────────────────────────────────────────────────────────────────

data class HealthAlert(
    val id: String,
    val type: AlertType,
    val title: String,
    val description: String,
    val timeLabel: String,
    val actionLabel: String? = null
)

enum class AlertType { URGENT, WARNING, INFO, OK }

// ─── Medications ─────────────────────────────────────────────────────────────

data class Medication(
    val id: String,
    val name: String,
    val dosage: String,
    val scheduleTime: String,
    val takenToday: Boolean = false,
    val daysRemaining: Int = 0
)

data class MedicationAdherence(
    val weeklyPercentage: Int,
    val dailyData: List<Int>   // 0–100 per day, last 7 days
)

// ─── Delivery / Logistics ─────────────────────────────────────────────────────

data class DeliveryOrder(
    val id: String,
    val orderCode: String,
    val description: String,
    val pharmacyName: String,
    val status: DeliveryStatus,
    val currentStep: Int,       // 0-based index in steps
    val etaFrom: String,
    val etaTo: String,
    val distanceKm: Double,
    val proactiveMessage: String? = null,
    val minutesAway: Int? = null
)

enum class DeliveryStatus {
    CONFIRMED, PREPARING, IN_TRANSIT, DELIVERED, CANCELLED
}

data class DeliveryStep(
    val label: String,
    val done: Boolean,
    val current: Boolean
)

fun DeliveryOrder.buildSteps(): List<DeliveryStep> {
    val labels = listOf("Confirmado", "Separado", "Em rota", "Entregue")
    return labels.mapIndexed { index, label ->
        DeliveryStep(
            label   = label,
            done    = index < currentStep,
            current = index == currentStep
        )
    }
}

data class HomeCareVisit(
    val id: String,
    val professionalName: String,
    val specialty: String,
    val description: String,
    val scheduledDateTime: String,
    val estimatedMinutes: Int,
    val confidencePercent: Int,
    val similarCasesCount: Int
)

// ─── Teleconsultation ─────────────────────────────────────────────────────────

data class Doctor(
    val id: String,
    val name: String,
    val initials: String,
    val specialty: String,
    val crm: String,
    val available: Boolean = false,
    val avatarUrl: String? = null
)

data class Appointment(
    val id: String,
    val doctor: Doctor,
    val dateTimeLabel: String,
    val dateTimeShort: String,
    val isToday: Boolean = false,
    val status: AppointmentStatus
)

enum class AppointmentStatus { SCHEDULED, CONFIRMED, ACTIVE, COMPLETED, CANCELLED }

data class NursingQueue(
    val queueSize: Int,
    val estimatedWaitMinutes: Int,
    val aiUpdating: Boolean = true
)

// ─── Analytics / Charts ───────────────────────────────────────────────────────

data class MetricSeries(
    val label: String,
    val currentValue: String,
    val unit: String,
    val trend: String,
    val trendUp: Boolean,
    val weeklyData: List<Float>,    // 7 data points, normalized 0..1
    val colorType: MetricColor
)

enum class MetricColor { RED, BLUE, AMBER, GREEN }

data class AiInsight(
    val title: String,
    val description: String,
    val severity: InsightSeverity
)

enum class InsightSeverity { INFO, WARNING, CRITICAL }

// ─── AI Chat ──────────────────────────────────────────────────────────────────

data class ChatMessage(
    val id: String,
    val role: MessageRole,
    val content: String,
    val timeLabel: String
)

enum class MessageRole { AI, USER }

data class QuickPrompt(
    val label: String,
    val message: String,
    val chipColor: ChipColor
)

enum class ChipColor { GREEN, BLUE, AMBER }
