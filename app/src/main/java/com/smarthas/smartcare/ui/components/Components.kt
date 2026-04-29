package com.smarthas.smartcare.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.data.model.*
import com.smarthas.smartcare.ui.theme.*

// ─── SmartCare Card ───────────────────────────────────────────────────────────

@Composable
fun ScCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier  = modifier.fillMaxWidth(),
        shape     = RoundedCornerShape(16.dp),
        colors    = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border    = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline)
    ) {
        Column(modifier = Modifier.padding(16.dp), content = content)
    }
}

// ─── Avatar Circle ────────────────────────────────────────────────────────────

@Composable
fun AvatarCircle(
    initials: String,
    size: Dp = 44.dp,
    backgroundColor: Color = PrimaryGreenLight,
    textColor: Color = PrimaryGreenDark
) {
    Box(
        modifier        = Modifier
            .size(size)
            .clip(CircleShape)
            .background(backgroundColor),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text  = initials,
            style = MaterialTheme.typography.labelLarge,
            color = textColor,
            fontWeight = FontWeight.Medium
        )
    }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

@Composable
fun StatusBadge(
    text: String,
    backgroundColor: Color = PrimaryGreen,
    textColor: Color = Color.White
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor)
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(text = text, style = MaterialTheme.typography.labelSmall, color = textColor)
    }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

@Composable
fun AlertCard(alert: HealthAlert, onActionClick: (() -> Unit)? = null) {
    val (bg, dot, border) = when (alert.type) {
        AlertType.URGENT  -> Triple(DangerRedLight,    DangerRed,    DangerRed.copy(alpha = 0.25f))
        AlertType.WARNING -> Triple(WarnAmberLight,    WarnAmber,    WarnAmber.copy(alpha = 0.25f))
        AlertType.INFO    -> Triple(AccentBlueLight,   AccentBlue,   AccentBlue.copy(alpha = 0.25f))
        AlertType.OK      -> Triple(PrimaryGreenLight, PrimaryGreen, PrimaryGreen.copy(alpha = 0.25f))
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .border(0.5.dp, border, RoundedCornerShape(12.dp))
            .padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .offset(y = 5.dp)
                .clip(CircleShape)
                .background(dot)
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(alert.title,       style = MaterialTheme.typography.titleMedium)
            Text(alert.description, style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                 modifier = Modifier.padding(top = 2.dp))
            Text(alert.timeLabel,   style = MaterialTheme.typography.labelSmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                 modifier = Modifier.padding(top = 4.dp))
        }
        if (alert.actionLabel != null && onActionClick != null) {
            TextButton(onClick = onActionClick) {
                Text(alert.actionLabel, style = MaterialTheme.typography.labelSmall, color = PrimaryGreen)
            }
        }
    }
}

// ─── Vital Chip ───────────────────────────────────────────────────────────────

@Composable
fun VitalChip(icon: String, value: String, unit: String, valueColor: Color) {
    Column(
        modifier         = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface)
            .border(0.5.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(icon, fontSize = 16.sp)
        Spacer(Modifier.height(4.dp))
        Text(value, style = MaterialTheme.typography.titleMedium, color = valueColor, fontWeight = FontWeight.Medium)
        Text(unit,  style = MaterialTheme.typography.labelSmall,  color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
    }
}

// ─── Mini Bar Chart ──────────────────────────────────────────────────────────

@Composable
fun MiniBarChart(
    data: List<Float>,
    activeColor: Color = PrimaryGreen,
    modifier: Modifier = Modifier
) {
    val barColor = activeColor.copy(alpha = 0.25f)
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp)
    ) {
        val barWidth  = (size.width - (data.size - 1) * 4.dp.toPx()) / data.size
        data.forEachIndexed { i, v ->
            val isLast = i == data.lastIndex
            val x      = i * (barWidth + 4.dp.toPx())
            val h      = v * size.height
            val y      = size.height - h
            drawRoundRect(
                color        = if (isLast) activeColor else barColor,
                topLeft      = Offset(x, y),
                size         = androidx.compose.ui.geometry.Size(barWidth, h),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(3.dp.toPx())
            )
        }
    }
}

// ─── Pulsing Dot (live indicator) ────────────────────────────────────────────

@Composable
fun PulsingDot(color: Color = PrimaryGreen, size: Dp = 8.dp) {
    val inf = rememberInfiniteTransition(label = "pulse")
    val scale by inf.animateFloat(
        initialValue   = 1f,
        targetValue    = 1.5f,
        animationSpec  = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
        label          = "scale"
    )
    Box(
        modifier = Modifier
            .size(size * scale)
            .clip(CircleShape)
            .background(color.copy(alpha = 0.4f)),
        contentAlignment = Alignment.Center
    ) {
        Box(modifier = Modifier.size(size).clip(CircleShape).background(color))
    }
}

// ─── Section Label ───────────────────────────────────────────────────────────

@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier) {
    Text(
        text     = text.uppercase(),
        style    = MaterialTheme.typography.labelSmall,
        color    = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f),
        modifier = modifier.padding(bottom = 8.dp)
    )
}

// ─── Primary Button ──────────────────────────────────────────────────────────

@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(
        onClick  = onClick,
        modifier = modifier.fillMaxWidth().height(48.dp),
        shape    = RoundedCornerShape(12.dp),
        colors   = ButtonDefaults.buttonColors(containerColor = PrimaryGreen)
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Medium)
    }
}

// ─── Outline Button ──────────────────────────────────────────────────────────

@Composable
fun OutlineButton(text: String, color: Color = PrimaryGreen, onClick: () -> Unit, modifier: Modifier = Modifier) {
    OutlinedButton(
        onClick  = onClick,
        modifier = modifier.height(40.dp),
        shape    = RoundedCornerShape(10.dp),
        border   = BorderStroke(1.dp, color),
        colors   = ButtonDefaults.outlinedButtonColors(contentColor = color)
    ) {
        Text(text, style = MaterialTheme.typography.labelSmall)
    }
}

// ─── Quick Action Button ─────────────────────────────────────────────────────

@Composable
fun QuickActionButton(icon: String, label: String, sub: String, onClick: () -> Unit) {
    Surface(
        onClick   = onClick,
        modifier  = Modifier.fillMaxWidth(),
        shape     = RoundedCornerShape(14.dp),
        color     = MaterialTheme.colorScheme.surface,
        border    = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline),
        tonalElevation = 0.dp
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(icon,  fontSize  = 20.sp)
            Spacer(Modifier.height(6.dp))
            Text(label, style = MaterialTheme.typography.titleMedium)
            Text(sub,   style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                 modifier = Modifier.padding(top = 2.dp))
        }
    }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

@Composable
fun SmartChip(text: String, chipColor: ChipColor, onClick: () -> Unit) {
    val (bg, fg, border) = when (chipColor) {
        ChipColor.GREEN -> Triple(PrimaryGreenLight, PrimaryGreenDark, PrimaryGreen.copy(alpha = 0.25f))
        ChipColor.BLUE  -> Triple(AccentBlueLight,   AccentBlueDark,   AccentBlue.copy(alpha = 0.25f))
        ChipColor.AMBER -> Triple(WarnAmberLight,     WarnAmber,        WarnAmber.copy(alpha = 0.25f))
    }
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(bg)
            .border(0.5.dp, border, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(text, style = MaterialTheme.typography.labelSmall, color = fg)
    }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

@Composable
fun SmartTopBar(
    greeting: String,
    title: String,
    trailingIcon: String? = null,
    badge: Int = 0,
    onTrailingClick: (() -> Unit)? = null,
    onInfoClick: (() -> Unit)? = null
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(PrimaryGreenDark)
            .padding(horizontal = 20.dp, vertical = 16.dp)
    ) {
        Column {
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(greeting, style = MaterialTheme.typography.bodySmall,
                         color = Color.White.copy(alpha = 0.7f))
                    Text(title, style = MaterialTheme.typography.headlineSmall,
                         color = Color.White, modifier = Modifier.padding(top = 2.dp))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (onInfoClick != null) {
                        Box(
                            modifier         = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(Color.White.copy(alpha = 0.12f))
                                .clickable { onInfoClick() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text("ℹ️", fontSize = 16.sp)
                        }
                    }
                    if (trailingIcon != null) {
                        Box(
                            modifier         = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(Color.White.copy(alpha = 0.18f))
                                .clickable { onTrailingClick?.invoke() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(trailingIcon, fontSize = 16.sp)
                            if (badge > 0) {
                                Box(
                                    modifier         = Modifier
                                        .align(Alignment.TopEnd)
                                        .offset(x = 4.dp, y = (-4).dp)
                                        .size(16.dp)
                                        .clip(CircleShape)
                                        .background(DangerRed)
                                        .border(2.dp, PrimaryGreenDark, CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("$badge", fontSize = 8.sp, color = Color.White)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────

@Composable
fun MetricCard(series: MetricSeries) {
    val activeColor = when (series.colorType) {
        MetricColor.RED   -> DangerRed
        MetricColor.BLUE  -> AccentBlue
        MetricColor.AMBER -> WarnAmber
        MetricColor.GREEN -> PrimaryGreen
    }
    ScCard {
        Text(series.label.uppercase(),
             style = MaterialTheme.typography.labelSmall,
             color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
        Spacer(Modifier.height(4.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Text(series.currentValue,
                 style = MaterialTheme.typography.headlineMedium,
                 color = activeColor,
                 fontWeight = FontWeight.Medium)
            Spacer(Modifier.width(4.dp))
            Text(series.unit,
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f))
        }
        Text(series.trend,
             style = MaterialTheme.typography.bodySmall,
             color = if (series.trendUp && series.colorType == MetricColor.AMBER) WarnAmber else PrimaryGreen,
             modifier = Modifier.padding(bottom = 8.dp))
        MiniBarChart(series.weeklyData, activeColor = activeColor)
    }
}
