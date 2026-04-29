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
import com.smarthas.smartcare.viewmodel.AnalyticsUiState

@Composable
fun AnalyticsScreen(
    state: AnalyticsUiState,
    onPeriodSelect: (Int) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {

        SmartTopBar(
            greeting     = "Dashboard Clínico",
            title        = "Meus dados de saúde",
            trailingIcon = "📊"
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(Modifier.height(16.dp))

            // Period selector chips
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(7 to "7 dias", 30 to "30 dias", 90 to "90 dias").forEach { (days, label) ->
                    PeriodChip(
                        label    = label,
                        selected = state.selectedPeriodDays == days,
                        onClick  = { onPeriodSelect(days) }
                    )
                }
            }

            Spacer(Modifier.height(16.dp))

            if (state.loading) {
                Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = PrimaryGreen)
                }
            } else {
                // Metrics 2x2 grid
                val chunked = state.metrics.chunked(2)
                chunked.forEach { row ->
                    Row(
                        modifier              = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        row.forEach { series ->
                            Box(modifier = Modifier.weight(1f)) {
                                MetricCard(series)
                            }
                        }
                        if (row.size == 1) {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                }

                // Medication adherence detail
                Spacer(Modifier.height(8.dp))
                SectionLabel("adesão a medicamentos")
                MedicationDetailCard()

                // AI Insight
                state.aiInsight?.let { insight ->
                    Spacer(Modifier.height(8.dp))
                    SectionLabel("insight da IA")
                    AiInsightCard(insight = insight)
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

// ─── Period Chip ─────────────────────────────────────────────────────────────

@Composable
private fun PeriodChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(if (selected) PrimaryGreenLight else MaterialTheme.colorScheme.surface)
            .border(
                width = if (selected) 1.5.dp else 0.5.dp,
                color = if (selected) PrimaryGreen.copy(alpha = 0.4f) else MaterialTheme.colorScheme.outline,
                shape = RoundedCornerShape(14.dp)
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 7.dp)
    ) {
        Text(
            text  = label,
            style = MaterialTheme.typography.labelSmall,
            color = if (selected) PrimaryGreenDark else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
            fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal
        )
    }
}

// ─── Medication Detail Card ───────────────────────────────────────────────────

@Composable
private fun MedicationDetailCard() {
    val medications = listOf(
        Triple("Metformina 500mg",  "08h e 12h",  true),
        Triple("Losartana 50mg",    "08h",        true),
        Triple("Insulina NPH 10UI", "22h",        false),
        Triple("AAS 100mg",         "08h",        true),
    )

    ScCard {
        medications.forEachIndexed { index, (name, schedule, taken) ->
            Row(
                modifier              = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(if (taken) PrimaryGreen else MaterialTheme.colorScheme.outline)
                    )
                    Column {
                        Text(name, style = MaterialTheme.typography.bodyMedium)
                        Text(schedule,
                             style = MaterialTheme.typography.bodySmall,
                             color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                    }
                }
                Text(
                    text  = if (taken) "✓ Tomado" else "Pendente",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (taken) PrimaryGreen else WarnAmber,
                    fontWeight = FontWeight.Medium
                )
            }
            if (index < medications.lastIndex) {
                HorizontalDivider(
                    color     = MaterialTheme.colorScheme.outline,
                    thickness = 0.5.dp,
                    modifier  = Modifier.padding(vertical = 2.dp)
                )
            }
        }
    }
}

// ─── AI Insight Card ─────────────────────────────────────────────────────────

@Composable
private fun AiInsightCard(insight: AiInsight) {
    val (bg, border, iconBg) = when (insight.severity) {
        InsightSeverity.WARNING  -> Triple(WarnAmberLight,  WarnAmber.copy(alpha = 0.2f),  WarnAmberLight)
        InsightSeverity.CRITICAL -> Triple(DangerRedLight,  DangerRed.copy(alpha = 0.2f),  DangerRedLight)
        InsightSeverity.INFO     -> Triple(AccentBlueLight, AccentBlue.copy(alpha = 0.2f), AccentBlueLight)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(bg)
            .border(0.5.dp, border, RoundedCornerShape(14.dp))
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment     = Alignment.Top
    ) {
        Box(
            modifier         = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(iconBg),
            contentAlignment = Alignment.Center
        ) {
            Text("🧠", fontSize = 18.sp)
        }
        Column {
            Text(insight.title,
                 style = MaterialTheme.typography.titleMedium,
                 color = MaterialTheme.colorScheme.onSurface)
            Text(insight.description,
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f),
                 modifier = Modifier.padding(top = 4.dp),
                 lineHeight = 18.sp)
        }
    }
}
