package com.smarthas.smartcare.ui.screens

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.data.model.*
import com.smarthas.smartcare.ui.components.*
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.ConsultaUiState

@Composable
fun ConsultaScreen(
    state: ConsultaUiState,
    onJoinQueue: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {

        SmartTopBar(
            greeting     = "Telemedicina",
            title        = "Consultas & Agenda",
            trailingIcon = "📹"
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(Modifier.height(16.dp))

            if (state.loading) {
                Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = PrimaryGreen)
                }
            } else {
                // Today's confirmed appointment
                state.todayAppointments.firstOrNull()?.let { apt ->
                    SectionLabel("consulta de hoje")
                    TodayAppointmentCard(appointment = apt)
                    Spacer(Modifier.height(16.dp))
                }

                // Upcoming appointments
                if (state.upcomingAppointments.isNotEmpty()) {
                    SectionLabel("próximas consultas")
                    ScCard {
                        state.upcomingAppointments.forEachIndexed { index, apt ->
                            UpcomingAppointmentRow(appointment = apt)
                            if (index < state.upcomingAppointments.lastIndex) {
                                HorizontalDivider(
                                    color     = MaterialTheme.colorScheme.outline,
                                    thickness = 0.5.dp,
                                    modifier  = Modifier.padding(vertical = 4.dp)
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }

                // Nursing queue (AI)
                state.nursingQueue?.let { queue ->
                    SectionLabel("fila inteligente")
                    NursingQueueCard(queue = queue, onJoinQueue = onJoinQueue)
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

// ─── Today's Appointment Card ─────────────────────────────────────────────────

@Composable
private fun TodayAppointmentCard(appointment: Appointment) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(PrimaryGreenLight)
            .border(0.5.dp, PrimaryGreen.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Column {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    AvatarCircle(
                        initials         = appointment.doctor.initials,
                        size             = 48.dp,
                        backgroundColor  = PrimaryGreen,
                        textColor        = Color.White
                    )
                    Column {
                        Text(appointment.doctor.name,
                             style = MaterialTheme.typography.titleLarge,
                             color = MaterialTheme.colorScheme.onSurface)
                        Text("${appointment.doctor.specialty} · ${appointment.doctor.crm}",
                             style = MaterialTheme.typography.bodySmall,
                             color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(appointment.dateTimeLabel,
                         style = MaterialTheme.typography.titleMedium,
                         color = PrimaryGreenDark,
                         fontWeight = FontWeight.Medium)
                    Text(appointment.dateTimeShort,
                         style = MaterialTheme.typography.bodySmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                }
            }

            if (appointment.doctor.available) {
                Spacer(Modifier.height(12.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White.copy(alpha = 0.6f))
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Box(modifier = Modifier.size(8.dp).clip(CircleShape).background(PrimaryGreen))
                    Text("Médico disponível agora · Sala pronta",
                         style = MaterialTheme.typography.bodySmall,
                         color = PrimaryGreenDark,
                         fontWeight = FontWeight.Medium)
                }
            }

            Spacer(Modifier.height(12.dp))
            PrimaryButton("Entrar na consulta agora", onClick = {})
        }
    }
}

// ─── Upcoming Appointment Row ─────────────────────────────────────────────────

@Composable
private fun UpcomingAppointmentRow(appointment: Appointment) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment     = Alignment.CenterVertically
    ) {
        AvatarCircle(
            initials        = appointment.doctor.initials,
            size            = 40.dp,
            backgroundColor = PrimaryGreenLight,
            textColor       = PrimaryGreenDark
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(appointment.doctor.name,
                 style = MaterialTheme.typography.titleMedium)
            Text(appointment.doctor.specialty,
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
            Text(appointment.dateTimeLabel,
                 style = MaterialTheme.typography.bodySmall,
                 color = AccentBlue,
                 fontWeight = FontWeight.Medium,
                 modifier = Modifier.padding(top = 2.dp))
        }
        OutlineButton("Reagendar", onClick = {})
    }
}

// ─── Nursing Queue Card ───────────────────────────────────────────────────────

@Composable
private fun NursingQueueCard(queue: NursingQueue, onJoinQueue: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AccentBlueLight)
            .border(0.5.dp, AccentBlue.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Column {
            Text("Plantão de enfermagem online",
                 style = MaterialTheme.typography.titleMedium,
                 color = MaterialTheme.colorScheme.onSurface)

            Spacer(Modifier.height(12.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment     = Alignment.CenterVertically
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("${queue.queueSize}",
                         style = MaterialTheme.typography.headlineMedium,
                         color = MaterialTheme.colorScheme.onSurface,
                         fontWeight = FontWeight.Medium)
                    Text("na fila",
                         style = MaterialTheme.typography.bodySmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                }

                Box(modifier = Modifier.width(1.dp).height(40.dp).background(MaterialTheme.colorScheme.outline))

                Column {
                    Text("Você será atendido em",
                         style = MaterialTheme.typography.bodySmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f))
                    Text("~${queue.estimatedWaitMinutes} min",
                         style = MaterialTheme.typography.headlineSmall,
                         color = AccentBlue,
                         fontWeight = FontWeight.Medium)
                    Text("estimativa IA · atualiza em tempo real",
                         style = MaterialTheme.typography.labelSmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.45f))
                }
            }

            Spacer(Modifier.height(12.dp))

            Button(
                onClick  = onJoinQueue,
                modifier = Modifier.fillMaxWidth().height(44.dp),
                shape    = RoundedCornerShape(10.dp),
                colors   = ButtonDefaults.buttonColors(containerColor = AccentBlue)
            ) {
                Text("Entrar na fila", style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}
