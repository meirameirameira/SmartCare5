package com.smarthas.smartcare.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// ─── SmartCare Brand Colors ───────────────────────────────────────────────────

val PrimaryGreen       = Color(0xFF1D9E75)
val PrimaryGreenDark   = Color(0xFF0F6E56)
val PrimaryGreenLight  = Color(0xFFE1F5EE)
val PrimaryGreenMid    = Color(0xFF9FE1CB)

val AccentBlue         = Color(0xFF378ADD)
val AccentBlueDark     = Color(0xFF185FA5)
val AccentBlueLight    = Color(0xFFE6F1FB)

val WarnAmber          = Color(0xFFBA7517)
val WarnAmberLight     = Color(0xFFFAEEDA)
val WarnAmberMid       = Color(0xFFFAC775)

val DangerRed          = Color(0xFFE24B4A)
val DangerRedLight     = Color(0xFFFCEBEB)

val BackgroundLight    = Color(0xFFF0F4F8)
val SurfaceLight       = Color(0xFFFFFFFF)
val OnSurfaceLight     = Color(0xFF2C2C2A)
val MutedGray          = Color(0xFF5F5E5A)
val BorderGray         = Color(0x14000000)

val BackgroundDark     = Color(0xFF121614)
val SurfaceDark        = Color(0xFF1C2421)
val OnSurfaceDark      = Color(0xFFE8F0EC)

// ─── Color Schemes ────────────────────────────────────────────────────────────

private val LightColorScheme = lightColorScheme(
    primary           = PrimaryGreen,
    onPrimary         = Color.White,
    primaryContainer  = PrimaryGreenLight,
    onPrimaryContainer = PrimaryGreenDark,
    secondary         = AccentBlue,
    onSecondary       = Color.White,
    secondaryContainer = AccentBlueLight,
    onSecondaryContainer = AccentBlueDark,
    tertiary          = WarnAmber,
    tertiaryContainer = WarnAmberLight,
    error             = DangerRed,
    errorContainer    = DangerRedLight,
    background        = BackgroundLight,
    surface           = SurfaceLight,
    onBackground      = OnSurfaceLight,
    onSurface         = OnSurfaceLight,
    surfaceVariant    = Color(0xFFF5F7F6),
    outline           = BorderGray
)

private val DarkColorScheme = darkColorScheme(
    primary           = PrimaryGreenMid,
    onPrimary         = PrimaryGreenDark,
    primaryContainer  = PrimaryGreenDark,
    onPrimaryContainer = PrimaryGreenMid,
    secondary         = AccentBlue,
    onSecondary       = Color.White,
    secondaryContainer = AccentBlueDark,
    onSecondaryContainer = AccentBlueLight,
    tertiary          = WarnAmberMid,
    tertiaryContainer = Color(0xFF3B2A05),
    error             = DangerRed,
    errorContainer    = Color(0xFF4A1515),
    background        = BackgroundDark,
    surface           = SurfaceDark,
    onBackground      = OnSurfaceDark,
    onSurface         = OnSurfaceDark,
    surfaceVariant    = Color(0xFF232E29),
    outline           = Color(0x1FFFFFFF)
)

// ─── Typography ───────────────────────────────────────────────────────────────

val SmartCareTypography = Typography(
    displayLarge = TextStyle(
        fontWeight = FontWeight.Light, fontSize = 48.sp, letterSpacing = (-0.5).sp
    ),
    headlineLarge = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 28.sp, letterSpacing = 0.sp
    ),
    headlineMedium = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 22.sp, letterSpacing = 0.sp
    ),
    headlineSmall = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 18.sp, letterSpacing = 0.sp
    ),
    titleLarge = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 16.sp, letterSpacing = 0.sp
    ),
    titleMedium = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 14.sp, letterSpacing = 0.15.sp
    ),
    bodyLarge = TextStyle(
        fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 26.sp
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 22.sp
    ),
    bodySmall = TextStyle(
        fontWeight = FontWeight.Normal, fontSize = 12.sp, lineHeight = 18.sp
    ),
    labelLarge = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 13.sp
    ),
    labelSmall = TextStyle(
        fontWeight = FontWeight.Medium, fontSize = 10.sp, letterSpacing = 0.5.sp
    )
)

// ─── Theme Composable ─────────────────────────────────────────────────────────

@Composable
fun SmartCareTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
        typography   = SmartCareTypography,
        content      = content
    )
}
