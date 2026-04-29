package com.smarthas.smartcare.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.smarthas.smartcare.data.local.LocalPrefs
import com.smarthas.smartcare.data.model.*
import com.smarthas.smartcare.data.repository.SmartCareRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.util.UUID

// ─── UI State classes ─────────────────────────────────────────────────────────

data class HomeUiState(
    val patient: Patient? = null,
    val vitals: VitalReading? = null,
    val healthScore: HealthScore? = null,
    val alerts: List<HealthAlert> = emptyList(),
    val loading: Boolean = true
)

data class DeliveryUiState(
    val activeDeliveries: List<DeliveryOrder> = emptyList(),
    val homeCareVisits: List<HomeCareVisit> = emptyList(),
    val deliveryHistory: List<DeliveryOrder> = emptyList(),
    val loading: Boolean = true
)

data class ConsultaUiState(
    val todayAppointments: List<Appointment> = emptyList(),
    val upcomingAppointments: List<Appointment> = emptyList(),
    val nursingQueue: NursingQueue? = null,
    val loading: Boolean = true
)

data class AnalyticsUiState(
    val metrics: List<MetricSeries> = emptyList(),
    val aiInsight: AiInsight? = null,
    val selectedPeriodDays: Int = 7,
    val loading: Boolean = true
)

data class ChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val quickPrompts: List<QuickPrompt> = emptyList(),
    val isTyping: Boolean = false
)

data class NotesUiState(
    val noteForToday: String? = null,
    val allNotes: Map<String, String> = emptyMap()
)

// ─── ViewModel ────────────────────────────────────────────────────────────────

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val repo  = SmartCareRepository()
    private val prefs = LocalPrefs(application)

    // ── Home ─────────────────────────────────────────────────────────────────

    private val _homeState = MutableStateFlow(HomeUiState())
    val homeState: StateFlow<HomeUiState> = _homeState.asStateFlow()

    // ── Delivery ─────────────────────────────────────────────────────────────

    private val _deliveryState = MutableStateFlow(DeliveryUiState())
    val deliveryState: StateFlow<DeliveryUiState> = _deliveryState.asStateFlow()

    // ── Consulta ─────────────────────────────────────────────────────────────

    private val _consultaState = MutableStateFlow(ConsultaUiState())
    val consultaState: StateFlow<ConsultaUiState> = _consultaState.asStateFlow()

    // ── Analytics ────────────────────────────────────────────────────────────

    private val _analyticsState = MutableStateFlow(AnalyticsUiState())
    val analyticsState: StateFlow<AnalyticsUiState> = _analyticsState.asStateFlow()

    // ── Chat ─────────────────────────────────────────────────────────────────

    private val _chatState = MutableStateFlow(ChatUiState())
    val chatState: StateFlow<ChatUiState> = _chatState.asStateFlow()

    // ── Notes ─────────────────────────────────────────────────────────────────

    private val _notesState = MutableStateFlow(NotesUiState())
    val notesState: StateFlow<NotesUiState> = _notesState.asStateFlow()

    // ─────────────────────────────────────────────────────────────────────────

    init {
        loadHome()
        loadDelivery()
        loadConsulta()
        loadAnalytics()
        loadChat()
        loadNotes()
        startVitalStream()
    }

    // ── Loaders ──────────────────────────────────────────────────────────────

    private fun loadHome() = viewModelScope.launch {
        val patient = repo.getPatient()
        val score   = repo.getHealthScore()
        val alerts  = repo.getAlerts()
        _homeState.update { it.copy(patient = patient, healthScore = score, alerts = alerts, loading = false) }
    }

    private fun startVitalStream() = viewModelScope.launch {
        repo.vitalStream().collect { vitals ->
            _homeState.update { it.copy(vitals = vitals) }
        }
    }

    private fun loadDelivery() = viewModelScope.launch {
        val active  = repo.getActiveDeliveries()
        val visits  = repo.getHomeCareVisits()
        val history = repo.getDeliveryHistory()
        _deliveryState.update { it.copy(activeDeliveries = active, homeCareVisits = visits, deliveryHistory = history, loading = false) }
    }

    private fun loadConsulta() = viewModelScope.launch {
        val today    = repo.getTodayAppointments()
        val upcoming = repo.getUpcomingAppointments()
        val queue    = repo.getNursingQueue()
        _consultaState.update { it.copy(todayAppointments = today, upcomingAppointments = upcoming, nursingQueue = queue, loading = false) }
    }

    private fun loadAnalytics() = viewModelScope.launch {
        val metrics = repo.getMetricSeries()
        val insight = repo.getAiInsight()
        _analyticsState.update { it.copy(metrics = metrics, aiInsight = insight, loading = false) }
    }

    private fun loadChat() = viewModelScope.launch {
        val messages = repo.getInitialMessages()
        val prompts  = repo.getQuickPrompts()
        _chatState.update { it.copy(messages = messages, quickPrompts = prompts) }
    }

    // ── Actions ──────────────────────────────────────────────────────────────

    fun selectAnalyticsPeriod(days: Int) {
        _analyticsState.update { it.copy(selectedPeriodDays = days) }
    }

    fun sendChatMessage(text: String) {
        if (text.isBlank()) return
        val time = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"))

        val userMsg = ChatMessage(
            id        = UUID.randomUUID().toString(),
            role      = MessageRole.USER,
            content   = text,
            timeLabel = time
        )
        _chatState.update { it.copy(messages = it.messages + userMsg, isTyping = true) }

        viewModelScope.launch {
            val response = repo.sendChatMessage(text)
            val aiMsg = ChatMessage(
                id        = UUID.randomUUID().toString(),
                role      = MessageRole.AI,
                content   = response,
                timeLabel = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"))
            )
            _chatState.update { it.copy(messages = it.messages + aiMsg, isTyping = false) }
        }
    }

    fun confirmMedicationDelivery(orderId: String) {
        _deliveryState.update { state ->
            state.copy(
                activeDeliveries = state.activeDeliveries.map { order ->
                    if (order.id == orderId)
                        order.copy(proactiveMessage = "Presença confirmada. O entregador foi notificado!")
                    else order
                }
            )
        }
    }

    fun joinNursingQueue() {
        _consultaState.update { it.copy(nursingQueue = it.nursingQueue?.copy(queueSize = it.nursingQueue.queueSize + 1)) }
    }

    // ── Notes actions ─────────────────────────────────────────────────────────

    private fun loadNotes() {
        val all   = prefs.getHealthNotes()
        val today = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ISO_LOCAL_DATE)
        _notesState.update { NotesUiState(noteForToday = all[today], allNotes = all) }
    }

    fun saveHealthNote(date: String, text: String) {
        prefs.saveHealthNote(date, text)
        loadNotes()
    }

    fun deleteHealthNote(date: String) {
        prefs.deleteHealthNote(date)
        loadNotes()
    }
}
