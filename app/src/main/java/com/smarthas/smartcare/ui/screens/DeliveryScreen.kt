package com.smarthas.smartcare.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.data.model.*
import com.smarthas.smartcare.ui.components.*
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.DeliveryUiState

@Composable
fun DeliveryScreen(
    state: DeliveryUiState,
    onConfirmDelivery: (String) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {

        SmartTopBar(
            greeting     = "Logística Inteligente",
            title        = "Healthcare Delivery 5.0",
            trailingIcon = "🚚"
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
                // Active deliveries
                if (state.activeDeliveries.isNotEmpty()) {
                    SectionLabel("entrega ativa")
                    state.activeDeliveries.forEach { order ->
                        ActiveDeliveryCard(order = order, onConfirm = { onConfirmDelivery(order.id) })
                        Spacer(Modifier.height(10.dp))
                    }
                }

                // Home care visits
                if (state.homeCareVisits.isNotEmpty()) {
                    Spacer(Modifier.height(8.dp))
                    SectionLabel("atendimento domiciliar")
                    state.homeCareVisits.forEach { visit ->
                        HomeCareCard(visit = visit)
                        Spacer(Modifier.height(10.dp))
                    }
                }

                // Delivery history
                if (state.deliveryHistory.isNotEmpty()) {
                    Spacer(Modifier.height(8.dp))
                    SectionLabel("histórico de entregas")
                    ScCard {
                        state.deliveryHistory.forEachIndexed { index, order ->
                            DeliveryHistoryItem(order = order)
                            if (index < state.deliveryHistory.lastIndex) {
                                HorizontalDivider(
                                    color     = MaterialTheme.colorScheme.outline,
                                    thickness = 0.5.dp,
                                    modifier  = Modifier.padding(vertical = 6.dp)
                                )
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

// ─── Active Delivery Card ─────────────────────────────────────────────────────

@Composable
private fun ActiveDeliveryCard(order: DeliveryOrder, onConfirm: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AccentBlueLight)
            .border(0.5.dp, AccentBlue.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Column {
            // Header
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(order.description,
                         style = MaterialTheme.typography.titleLarge,
                         color = MaterialTheme.colorScheme.onSurface)
                    Text("${order.orderCode} · ${order.pharmacyName}",
                         style = MaterialTheme.typography.bodySmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                         modifier = Modifier.padding(top = 2.dp))
                }
                StatusBadge("Em rota", backgroundColor = AccentBlue)
            }

            Spacer(Modifier.height(16.dp))

            // Tracking steps
            TrackingSteps(steps = order.buildSteps())

            Spacer(Modifier.height(14.dp))

            // ETA box
            EtaBox(order = order)

            // Proactive AI message
            order.proactiveMessage?.let { msg ->
                Spacer(Modifier.height(10.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(AccentBlue.copy(alpha = 0.1f))
                        .padding(10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Text("💬", fontSize = 14.sp)
                    Column {
                        Text("Notificação proativa",
                             style = MaterialTheme.typography.labelSmall,
                             color = AccentBlueDark,
                             fontWeight = FontWeight.Medium)
                        Text(msg,
                             style = MaterialTheme.typography.bodySmall,
                             color = AccentBlueDark,
                             modifier = Modifier.padding(top = 2.dp))
                    }
                }
            }

            Spacer(Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick  = onConfirm,
                    modifier = Modifier.weight(1f).height(40.dp),
                    shape    = RoundedCornerShape(10.dp),
                    colors   = ButtonDefaults.buttonColors(containerColor = AccentBlue)
                ) {
                    Text("Confirmar presença", style = MaterialTheme.typography.labelSmall)
                }
                OutlinedButton(
                    onClick  = {},
                    modifier = Modifier.weight(1f).height(40.dp),
                    shape    = RoundedCornerShape(10.dp),
                    border   = BorderStroke(1.dp, AccentBlue),
                    colors   = ButtonDefaults.outlinedButtonColors(contentColor = AccentBlue)
                ) {
                    Text("Reagendar", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

// ─── Tracking Steps ──────────────────────────────────────────────────────────

@Composable
private fun TrackingSteps(steps: List<DeliveryStep>) {
    Box(modifier = Modifier.fillMaxWidth()) {
        // Connector line
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 10.dp)
                .height(2.dp)
                .align(Alignment.Center)
                .background(AccentBlue.copy(alpha = 0.15f))
        )
        // Progress line
        val completedFraction = steps.indexOfFirst { it.current }.takeIf { it >= 0 }?.let { it.toFloat() / (steps.size - 1) } ?: 0f
        Box(
            modifier = Modifier
                .fillMaxWidth(completedFraction)
                .padding(start = 10.dp)
                .height(2.dp)
                .align(Alignment.CenterStart)
                .background(AccentBlue)
        )

        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            steps.forEach { step ->
                TrackingStepDot(step)
            }
        }
    }
}

@Composable
private fun TrackingStepDot(step: DeliveryStep) {
    val inf = rememberInfiniteTransition(label = "pulse")
    val scale by inf.animateFloat(
        initialValue  = 1f,
        targetValue   = 1.3f,
        animationSpec = if (step.current)
            infiniteRepeatable(tween(900), RepeatMode.Reverse)
        else
            infiniteRepeatable(tween(0)),
        label = "scale"
    )

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier         = Modifier
                .size(if (step.current) (20 * scale).dp else 20.dp)
                .clip(CircleShape)
                .background(
                    when {
                        step.done || step.current -> AccentBlue
                        else                      -> Color.White
                    }
                )
                .border(2.dp,
                    if (step.done || step.current) AccentBlue else AccentBlue.copy(alpha = 0.3f),
                    CircleShape),
            contentAlignment = Alignment.Center
        ) {
            when {
                step.done    -> Text("✓", fontSize = 10.sp, color = Color.White)
                step.current -> Text("●", fontSize = 8.sp,  color = Color.White)
            }
        }
        Spacer(Modifier.height(6.dp))
        Text(
            text  = step.label,
            style = MaterialTheme.typography.labelSmall,
            color = if (step.done || step.current) AccentBlueDark
                    else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.45f),
            modifier = Modifier.widthIn(max = 64.dp)
        )
    }
}

// ─── ETA Box ─────────────────────────────────────────────────────────────────

@Composable
private fun EtaBox(order: DeliveryOrder) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(AccentBlue.copy(alpha = 0.1f))
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text("ETA inteligente (IA)",
                 style = MaterialTheme.typography.labelSmall,
                 color = AccentBlue,
                 fontWeight = FontWeight.Medium)
            Text("${order.etaFrom} — ${order.etaTo}",
                 style = MaterialTheme.typography.headlineSmall,
                 color = MaterialTheme.colorScheme.onSurface)
            Text("Rota otimizada · ${order.distanceKm} km restantes",
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
        }
        Text("📍", fontSize = 24.sp)
    }
}

// ─── Home Care Card ───────────────────────────────────────────────────────────

@Composable
private fun HomeCareCard(visit: HomeCareVisit) {
    ScCard {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(visit.professionalName,
                     style = MaterialTheme.typography.titleMedium)
                Text("${visit.specialty} · ${visit.description}",
                     style = MaterialTheme.typography.bodySmall,
                     color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
            }
            StatusBadge(visit.scheduledDateTime,
                        backgroundColor = PrimaryGreenLight,
                        textColor = PrimaryGreenDark)
        }

        Spacer(Modifier.height(12.dp))

        // AI time prediction box
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(PrimaryGreenLight)
                .padding(10.dp)
        ) {
            Column {
                Text("IA prevê tempo de atendimento",
                     style = MaterialTheme.typography.labelSmall,
                     color = PrimaryGreenDark,
                     fontWeight = FontWeight.Medium)
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.Bottom) {
                    Text("${visit.estimatedMinutes} min",
                         style = MaterialTheme.typography.headlineSmall,
                         color = MaterialTheme.colorScheme.onSurface)
                    Spacer(Modifier.width(8.dp))
                    Text("± 5 min (${visit.similarCasesCount} visitas similares)",
                         style = MaterialTheme.typography.bodySmall,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
                }
            }
        }
    }
}

// ─── History Item ─────────────────────────────────────────────────────────────

@Composable
private fun DeliveryHistoryItem(order: DeliveryOrder) {
    Row(
        modifier              = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(order.description, style = MaterialTheme.typography.titleMedium)
            Text("${order.etaFrom} · ${order.pharmacyName}",
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                 modifier = Modifier.padding(top = 2.dp))
        }
        Text("✓ Entregue",
             style = MaterialTheme.typography.labelSmall,
             color = PrimaryGreen,
             fontWeight = FontWeight.Medium)
    }
}
