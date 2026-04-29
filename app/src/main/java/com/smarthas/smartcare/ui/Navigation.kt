package com.smarthas.smartcare.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector

// ─── Bottom Nav Destinations ──────────────────────────────────────────────────

sealed class Screen(
    val route: String,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val emoji: String
) {
    data object Home : Screen(
        route          = "home",
        label          = "Início",
        selectedIcon   = Icons.Filled.Home,
        unselectedIcon = Icons.Outlined.Home,
        emoji          = "🏠"
    )
    data object Delivery : Screen(
        route          = "delivery",
        label          = "Entregas",
        selectedIcon   = Icons.Filled.LocalShipping,
        unselectedIcon = Icons.Outlined.LocalShipping,
        emoji          = "🚚"
    )
    data object Consulta : Screen(
        route          = "consulta",
        label          = "Consulta",
        selectedIcon   = Icons.Filled.VideoCall,
        unselectedIcon = Icons.Outlined.VideoCall,
        emoji          = "📹"
    )
    data object Analytics : Screen(
        route          = "analytics",
        label          = "Dados",
        selectedIcon   = Icons.Filled.BarChart,
        unselectedIcon = Icons.Outlined.BarChart,
        emoji          = "📊"
    )
    data object Ia : Screen(
        route          = "ia",
        label          = "IA",
        selectedIcon   = Icons.Filled.SmartToy,
        unselectedIcon = Icons.Outlined.SmartToy,
        emoji          = "🤖"
    )
    data object Notes : Screen(
        route          = "notes",
        label          = "Notas",
        selectedIcon   = Icons.Filled.Note,
        unselectedIcon = Icons.Outlined.Note,
        emoji          = "📝"
    )
    // Credits is not a BottomBar destination — navigated from Home TopBar
    data object Credits : Screen(
        route          = "credits",
        label          = "Créditos",
        selectedIcon   = Icons.Filled.Info,
        unselectedIcon = Icons.Outlined.Info,
        emoji          = "ℹ️"
    )
}

val bottomNavScreens = listOf(
    Screen.Home,
    Screen.Delivery,
    Screen.Consulta,
    Screen.Analytics,
    Screen.Ia,
    Screen.Notes
)
