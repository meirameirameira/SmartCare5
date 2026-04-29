package com.smarthas.smartcare.data.repository

import com.smarthas.smartcare.data.model.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

// ─── SmartCareRepository ──────────────────────────────────────────────────────
// In a real implementation this class would call the NestJS/FastAPI microservices
// via Retrofit. For demonstration, it returns realistic mock data that mirrors
// the SmartCare 5.0 planning document (Fase 2).

class SmartCareRepository {

    // ── Patient ──────────────────────────────────────────────────────────────

    suspend fun getPatient(): Patient {
        delay(300)
        return Patient(
            id                = "PAT-001",
            name              = "Carlos Souza",
            initials          = "CS",
            age               = 58,
            conditions        = listOf("Diabetes tipo 2", "Hipertensão"),
            wearableConnected = true,
            notificationCount = 3
        )
    }

    // ── Vitals (simulates IoT wearable stream) ───────────────────────────────

    fun vitalStream(): Flow<VitalReading> = flow {
        val baselines = VitalReading(
            heartRate              = 72,
            spO2                   = 98.0f,
            glucoseLevel           = 104,
            bloodPressureSystolic  = 128,
            bloodPressureDiastolic = 82,
            temperature            = 36.5f
        )
        var ticks = 0
        while (true) {
            val noiseHR  = (-2..2).random()
            val noiseGlu = (-3..3).random()
            emit(
                baselines.copy(
                    heartRate    = baselines.heartRate + noiseHR,
                    glucoseLevel = baselines.glucoseLevel + noiseGlu,
                    timestamp    = System.currentTimeMillis()
                )
            )
            ticks++
            delay(4_000)
        }
    }

    suspend fun getHealthScore(): HealthScore {
        delay(200)
        return HealthScore(
            score = 84,
            level = HealthLevel.GOOD,
            label = "Estável",
            trend = TrendDirection.STABLE
        )
    }

    // ── Alerts ───────────────────────────────────────────────────────────────

    suspend fun getAlerts(): List<HealthAlert> {
        delay(200)
        return listOf(
            HealthAlert(
                id          = "ALR-001",
                type        = AlertType.WARNING,
                title       = "Medicamento às 12h",
                description = "Metformina 500mg — confirme a dose",
                timeLabel   = "em 2h 18min",
                actionLabel = "Confirmar dose"
            ),
            HealthAlert(
                id          = "ALR-002",
                type        = AlertType.OK,
                title       = "Consulta confirmada",
                description = "Dr. Alves — Cardiologia — 14h30",
                timeLabel   = "Hoje",
                actionLabel = null
            ),
            HealthAlert(
                id          = "ALR-003",
                type        = AlertType.INFO,
                title       = "Entrega em rota",
                description = "Medicamentos crônicos a caminho",
                timeLabel   = "~12 min",
                actionLabel = "Rastrear"
            )
        )
    }

    // ── Medications ──────────────────────────────────────────────────────────

    suspend fun getMedications(): List<Medication> {
        delay(200)
        return listOf(
            Medication("MED-01", "Metformina",  "500mg",   "08:00", takenToday = true,  daysRemaining = 15),
            Medication("MED-02", "Metformina",  "500mg",   "12:00", takenToday = false, daysRemaining = 15),
            Medication("MED-03", "Losartana",   "50mg",    "08:00", takenToday = true,  daysRemaining = 22),
            Medication("MED-04", "Insulina NPH","10 UI",   "22:00", takenToday = false, daysRemaining = 8),
            Medication("MED-05", "AAS",         "100mg",   "08:00", takenToday = true,  daysRemaining = 30)
        )
    }

    suspend fun getMedicationAdherence(): MedicationAdherence {
        delay(150)
        return MedicationAdherence(
            weeklyPercentage = 86,
            dailyData        = listOf(70, 80, 75, 90, 85, 88, 86)
        )
    }

    // ── Delivery / Logistics ─────────────────────────────────────────────────

    suspend fun getActiveDeliveries(): List<DeliveryOrder> {
        delay(400)
        return listOf(
            DeliveryOrder(
                id               = "DEL-001",
                orderCode        = "#MED-2025-04712",
                description      = "Medicamentos crônicos",
                pharmacyName     = "Farmácia Sempre Bem",
                status           = DeliveryStatus.IN_TRANSIT,
                currentStep      = 2,
                etaFrom          = "12h15",
                etaTo            = "12h35",
                distanceKm       = 3.2,
                proactiveMessage = "Entregador chegará em ~12 min. Você está em casa?",
                minutesAway      = 12
            )
        )
    }

    suspend fun getHomeCareVisits(): List<HomeCareVisit> {
        delay(300)
        return listOf(
            HomeCareVisit(
                id                  = "HCV-001",
                professionalName    = "Enf. Carla Mendes",
                specialty           = "Enfermagem",
                description         = "Curativos pós-cirúrgicos",
                scheduledDateTime   = "Amanhã · 09h00",
                estimatedMinutes    = 35,
                confidencePercent   = 87,
                similarCasesCount   = 23
            )
        )
    }

    suspend fun getDeliveryHistory(): List<DeliveryOrder> {
        delay(300)
        return listOf(
            DeliveryOrder(
                id           = "DEL-H01",
                orderCode    = "#MED-2025-04320",
                description  = "Insulina + seringas",
                pharmacyName = "Farmácia Sempre Bem",
                status       = DeliveryStatus.DELIVERED,
                currentStep  = 3,
                etaFrom      = "02 abr",
                etaTo        = "02 abr",
                distanceKm   = 0.0
            ),
            DeliveryOrder(
                id           = "DEL-H02",
                orderCode    = "#HCV-2025-00198",
                description  = "Fisioterapia domiciliar",
                pharmacyName = "Ft. André Lima",
                status       = DeliveryStatus.DELIVERED,
                currentStep  = 3,
                etaFrom      = "28 mar",
                etaTo        = "28 mar",
                distanceKm   = 0.0
            )
        )
    }

    // ── Teleconsultation ─────────────────────────────────────────────────────

    suspend fun getTodayAppointments(): List<Appointment> {
        delay(250)
        return listOf(
            Appointment(
                id            = "APT-001",
                doctor        = Doctor("DOC-01", "Dr. Rafael Alves", "RA", "Cardiologia", "CRM 54.321", available = true),
                dateTimeLabel = "14h30",
                dateTimeShort = "Hoje",
                isToday       = true,
                status        = AppointmentStatus.CONFIRMED
            )
        )
    }

    suspend fun getUpcomingAppointments(): List<Appointment> {
        delay(250)
        return listOf(
            Appointment(
                id            = "APT-002",
                doctor        = Doctor("DOC-02", "Dra. Paula Mota", "PM", "Endocrinologia", "CRM 67.890"),
                dateTimeLabel = "08 abr · 10h00",
                dateTimeShort = "08/abr",
                status        = AppointmentStatus.SCHEDULED
            ),
            Appointment(
                id            = "APT-003",
                doctor        = Doctor("DOC-03", "Dr. João Lima", "JL", "Clínica Geral", "CRM 12.345"),
                dateTimeLabel = "15 abr · 16h30",
                dateTimeShort = "15/abr",
                status        = AppointmentStatus.SCHEDULED
            )
        )
    }

    suspend fun getNursingQueue(): NursingQueue {
        delay(200)
        return NursingQueue(queueSize = 3, estimatedWaitMinutes = 8)
    }

    // ── Analytics ────────────────────────────────────────────────────────────

    suspend fun getMetricSeries(): List<MetricSeries> {
        delay(300)
        return listOf(
            MetricSeries(
                label        = "Freq. cardíaca",
                currentValue = "74",
                unit         = "bpm",
                trend        = "↓ 3 bpm vs semana passada",
                trendUp      = false,
                weeklyData   = listOf(0.60f, 0.75f, 0.65f, 0.80f, 0.70f, 0.85f, 0.70f),
                colorType    = MetricColor.RED
            ),
            MetricSeries(
                label        = "Glicemia média",
                currentValue = "108",
                unit         = "mg/dL",
                trend        = "↑ 4 mg/dL — monitorar",
                trendUp      = true,
                weeklyData   = listOf(0.80f, 0.90f, 0.75f, 0.95f, 0.85f, 0.70f, 0.88f),
                colorType    = MetricColor.AMBER
            ),
            MetricSeries(
                label        = "SpO₂ média",
                currentValue = "97.8",
                unit         = "%",
                trend        = "→ Estável",
                trendUp      = false,
                weeklyData   = listOf(0.95f, 0.98f, 0.92f, 0.99f, 0.96f, 0.97f, 0.98f),
                colorType    = MetricColor.BLUE
            ),
            MetricSeries(
                label        = "Adesão medicamentos",
                currentValue = "86",
                unit         = "%",
                trend        = "↑ 12% vs semana passada",
                trendUp      = true,
                weeklyData   = listOf(0.70f, 0.80f, 0.75f, 0.90f, 0.85f, 0.88f, 0.86f),
                colorType    = MetricColor.GREEN
            )
        )
    }

    suspend fun getAiInsight(): AiInsight {
        delay(250)
        return AiInsight(
            title       = "Glicemia em tendência de alta",
            description = "A IA detectou alta de 8% na glicemia nos últimos 3 dias. " +
                          "Recomendamos verificar com Dra. Paula Mota na consulta de 08/abr.",
            severity    = InsightSeverity.WARNING
        )
    }

    // ── AI Chat ──────────────────────────────────────────────────────────────

    suspend fun getInitialMessages(): List<ChatMessage> {
        delay(100)
        return listOf(
            ChatMessage(
                id        = "MSG-001",
                role      = MessageRole.AI,
                content   = "Olá, Carlos! Sou sua IA de saúde. Posso analisar seus dados do wearable, responder dúvidas clínicas e ajudar com sua rotina de cuidados.",
                timeLabel = "09:41"
            ),
            ChatMessage(
                id        = "MSG-002",
                role      = MessageRole.AI,
                content   = "Com base nos seus dados de hoje, sua glicemia (104 mg/dL) está dentro do esperado, mas houve leve tendência de alta nos últimos 3 dias. Quer que eu notifique a Dra. Paula Mota?",
                timeLabel = "09:41"
            )
        )
    }

    suspend fun getQuickPrompts(): List<QuickPrompt> {
        return listOf(
            QuickPrompt("Como está minha glicemia?",     "Como está minha glicemia esta semana?",              ChipColor.GREEN),
            QuickPrompt("Rastrear entrega",              "Onde está minha entrega de medicamentos?",           ChipColor.BLUE),
            QuickPrompt("Remarcar consulta",             "Preciso remarcar minha consulta",                    ChipColor.AMBER),
            QuickPrompt("Score de risco hoje",           "Qual é meu score de risco de saúde hoje?",           ChipColor.GREEN),
            QuickPrompt("Pressão arterial",              "Como está minha pressão arterial esta semana?",      ChipColor.BLUE)
        )
    }

    // Simulates backend IA Engine response (RN01: score >= 70 triggers alert)
    suspend fun sendChatMessage(message: String): String {
        delay(900)
        return when {
            message.contains("glicemia", ignoreCase = true) ->
                "Sua glicemia média nos últimos 7 dias foi de 108 mg/dL, com pico de 127 mg/dL " +
                "na quinta-feira após o jantar. Está 8% acima da semana anterior. " +
                "Recomendo verificar com a Dra. Paula na consulta de 08/abr."

            message.contains("entrega", ignoreCase = true) || message.contains("medicamento", ignoreCase = true) ->
                "Sua encomenda #MED-2025-04712 está em rota! O entregador está a 3,2 km de você. " +
                "ETA estimado pela IA: 12h15–12h35. Você receberá uma notificação 10 min antes da chegada."

            message.contains("consulta", ignoreCase = true) || message.contains("remarcar", ignoreCase = true) ->
                "Entendido! Qual consulta você deseja remarcar?\n" +
                "• Dr. Rafael Alves — Cardiologia — Hoje 14h30\n" +
                "• Dra. Paula Mota — Endocrinologia — 08/abr 10h00\n\n" +
                "Responda com o nome do médico para continuar."

            message.contains("score", ignoreCase = true) || message.contains("risco", ignoreCase = true) ->
                "Seu score de saúde hoje é 84/100 — classificação ÓTIMO. " +
                "Frequência cardíaca e SpO₂ estão dentro da faixa ideal. " +
                "Atenção apenas à glicemia, que está levemente elevada."

            message.contains("pressão", ignoreCase = true) ->
                "Sua pressão arterial média esta semana foi 128/82 mmHg. " +
                "Está dentro do limite aceitável para seu perfil, mas próxima do limiar de hipertensão estágio 1. " +
                "Continue com a Losartana 50mg conforme prescrito."

            else ->
                "Entendido! Estou analisando seus dados de saúde — wearable, histórico clínico e prontuário — " +
                "para responder com precisão. Score atual: 84/100. Todos os sinais vitais estão monitorados. " +
                "Há algo específico que você gostaria de saber?"
        }
    }
}
