package com.smarthas.smartcare.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.ui.components.*
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.HomeUiState

@Composable
fun HomeScreen(
    state: HomeUiState,
    onNavigateToDelivery: () -> Unit,
    onNavigateToConsulta: () -> Unit,
    onNavigateToAnalytics: () -> Unit,
    onNavigateToIa: () -> Unit,
    onNavigateToCredits: () -> Unit = {}
) {
    Column(modifier = Modifier.fillMaxSize()) {

        // ── Top Bar ──────────────────────────────────────────────────────────
        SmartTopBar(
            greeting          = "Bom dia,",
            title             = state.patient?.name ?: "Carregando...",
            trailingIcon      = "👤",
            badge             = state.patient?.notificationCount ?: 0,
            onInfoClick       = onNavigateToCredits
        )

        // ── Scrollable Body ───────────────────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(Modifier.height(16.dp))

            // Health Score Hero
            HealthScoreCard(state = state)

            Spacer(Modifier.height(16.dp))
            SectionLabel("sinais vitais agora")

            // Vitals row
            state.vitals?.let { vitals ->
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    VitalChip("❤️", "${vitals.heartRate}", "bpm",    DangerRed,  modifier = Modifier.weight(1f))
                    VitalChip("🫁", "${vitals.spO2.toInt()}%", "SpO₂", AccentBlue, modifier = Modifier.weight(1f))
                    VitalChip("🩸", "${vitals.glucoseLevel}", "mg/dL", WarnAmber,  modifier = Modifier.weight(1f))
                }
            } ?: run {
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    VitalChip("❤️", "--", "bpm",    DangerRed,  modifier = Modifier.weight(1f))
                    VitalChip("🫁", "--", "SpO₂",  AccentBlue, modifier = Modifier.weight(1f))
                    VitalChip("🩸", "--", "mg/dL", WarnAmber,  modifier = Modifier.weight(1f))
                }
            }

            Spacer(Modifier.height(16.dp))
            SectionLabel("alertas de hoje")

            state.alerts.forEach { alert ->
                AlertCard(alert = alert)
                Spacer(Modifier.height(8.dp))
            }

            Spacer(Modifier.height(8.dp))
            SectionLabel("ações rápidas")

            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                QuickActionButton("🚚", "Rastrear entrega", "Medicamentos",   onNavigateToDelivery, modifier = Modifier.weight(1f))
                QuickActionButton("📹", "Consulta remota",  "14h30 hoje",     onNavigateToConsulta, modifier = Modifier.weight(1f))
            }
            Spacer(Modifier.height(8.dp))
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                QuickActionButton("📊", "Meus dados",   "7 dias",       onNavigateToAnalytics, modifier = Modifier.weight(1f))
                QuickActionButton("🤖", "IA de saúde",  "Pergunte algo", onNavigateToIa,       modifier = Modifier.weight(1f))
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

// ─── Health Score Hero Card ───────────────────────────────────────────────────

@Composable
private fun HealthScoreCard(state: HomeUiState) {
    val score = state.healthScore
    val vitals = state.vitals

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(
                Brush.linearGradient(
                    colors = listOf(PrimaryGreen, PrimaryGreenDark),
                    start  = Offset(0f, 0f),
                    end    = Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY)
                )
            )
            .padding(18.dp)
    ) {
        // Decorative circle
        Box(
            modifier = Modifier
                .size(100.dp)
                .offset(x = 20.dp, y = (-20).dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.06f))
                .align(Alignment.TopEnd)
        )

        Column {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.Top
            ) {
                Column {
                    Text("Score de saúde",
                         style = MaterialTheme.typography.labelLarge,
                         color = Color.White.copy(alpha = 0.7f))
                    Text(
                        text  = "${score?.score ?: "--"}",
                        style = MaterialTheme.typography.displayLarge,
                        color = Color.White,
                        fontWeight = FontWeight.Light,
                        fontSize   = 52.sp
                    )
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        PulsingDot(Color.White.copy(alpha = 0.8f), size = 6.dp)
                        Text(
                            text  = "Monitoramento ativo — wearable conectado",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.65f)
                        )
                    }
                }
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(Color.White.copy(alpha = 0.18f))
                        .padding(horizontal = 12.dp, vertical = 5.dp)
                ) {
                    Text(score?.label ?: "—",
                         style = MaterialTheme.typography.labelSmall,
                         color = Color.White)
                }
            }

            Spacer(Modifier.height(14.dp))
            HorizontalDivider(color = Color.White.copy(alpha = 0.2f), thickness = 0.5.dp)
            Spacer(Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                ScoreStatItem("Freq. cardíaca", "${vitals?.heartRate ?: 72} bpm")
                ScoreStatItem("SpO₂",           "${vitals?.spO2?.toInt() ?: 98}%")
                ScoreStatItem("Glicemia",        "${vitals?.glucoseLevel ?: 104} mg/dL")
            }
        }
    }
}

@Composable
private fun ScoreStatItem(label: String, value: String) {
    Column {
        Text(label, style = MaterialTheme.typography.bodySmall, color = Color.White.copy(alpha = 0.6f))
        Text(value, style = MaterialTheme.typography.titleMedium, color = Color.White, fontWeight = FontWeight.Medium)
    }
}

// ─── VitalChip with explicit modifier ────────────────────────────────────────

@Composable
private fun VitalChip(icon: String, value: String, unit: String, valueColor: Color, modifier: Modifier = Modifier) {
    Column(
        modifier             = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface)
            .border(0.5.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp),
        horizontalAlignment  = Alignment.CenterHorizontally
    ) {
        Text(icon,  fontSize = 16.sp)
        Spacer(Modifier.height(4.dp))
        Text(value, style = MaterialTheme.typography.titleMedium, color = valueColor, fontWeight = FontWeight.Medium)
        Text(unit,  style = MaterialTheme.typography.labelSmall,  color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
    }
}

@Composable
private fun QuickActionButton(icon: String, label: String, sub: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        onClick  = onClick,
        modifier = modifier,
        shape    = RoundedCornerShape(14.dp),
        color    = MaterialTheme.colorScheme.surface,
        border   = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(icon,  fontSize = 20.sp)
            Spacer(Modifier.height(6.dp))
            Text(label, style = MaterialTheme.typography.titleMedium)
            Text(sub,   style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                 modifier = Modifier.padding(top = 2.dp))
        }
    }
}
