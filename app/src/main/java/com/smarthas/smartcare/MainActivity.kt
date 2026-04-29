package com.smarthas.smartcare

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.*
import com.google.accompanist.systemuicontroller.rememberSystemUiController
import com.smarthas.smartcare.ui.*
import com.smarthas.smartcare.ui.screens.*
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.MainViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SmartCareTheme {
                SmartCareApp()
            }
        }
    }
}

@Composable
fun SmartCareApp() {
    val systemUiController = rememberSystemUiController()
    val vm: MainViewModel  = viewModel()
    val navController      = rememberNavController()

    // Collect states
    val homeState     by vm.homeState.collectAsState()
    val deliveryState by vm.deliveryState.collectAsState()
    val consultaState by vm.consultaState.collectAsState()
    val analytics     by vm.analyticsState.collectAsState()
    val chatState     by vm.chatState.collectAsState()
    val notesState    by vm.notesState.collectAsState()

    // Status bar: transparent so our dark-green top bars show edge-to-edge
    SideEffect {
        systemUiController.setStatusBarColor(
            color     = PrimaryGreenDark,
            darkIcons = false
        )
        systemUiController.setNavigationBarColor(
            color     = Color.White,
            darkIcons = true
        )
    }

    // Credits is a full-screen destination without BottomBar
    val navBackStackEntry    by navController.currentBackStackEntryAsState()
    val currentRoute         = navBackStackEntry?.destination?.route
    val showBottomBar        = currentRoute != Screen.Credits.route

    Scaffold(
        modifier       = Modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background,
        bottomBar      = {
            if (showBottomBar) {
                SmartBottomBar(navController = navController)
            }
        }
    ) { innerPadding ->
        NavHost(
            navController       = navController,
            startDestination    = Screen.Home.route,
            modifier            = Modifier.padding(innerPadding),
            enterTransition     = { fadeIn() + slideInHorizontally { it / 8 } },
            exitTransition      = { fadeOut() },
            popEnterTransition  = { fadeIn() },
            popExitTransition   = { fadeOut() + slideOutHorizontally { it / 8 } }
        ) {
            composable(Screen.Home.route) {
                HomeScreen(
                    state                 = homeState,
                    onNavigateToDelivery  = { navController.navigate(Screen.Delivery.route) },
                    onNavigateToConsulta  = { navController.navigate(Screen.Consulta.route) },
                    onNavigateToAnalytics = { navController.navigate(Screen.Analytics.route) },
                    onNavigateToIa        = { navController.navigate(Screen.Ia.route) },
                    onNavigateToCredits   = { navController.navigate(Screen.Credits.route) }
                )
            }
            composable(Screen.Delivery.route) {
                DeliveryScreen(
                    state             = deliveryState,
                    onConfirmDelivery = { vm.confirmMedicationDelivery(it) }
                )
            }
            composable(Screen.Consulta.route) {
                ConsultaScreen(
                    state       = consultaState,
                    onJoinQueue = { vm.joinNursingQueue() }
                )
            }
            composable(Screen.Analytics.route) {
                AnalyticsScreen(
                    state          = analytics,
                    onPeriodSelect = { vm.selectAnalyticsPeriod(it) }
                )
            }
            composable(Screen.Ia.route) {
                IaScreen(
                    state         = chatState,
                    onSendMessage = { vm.sendChatMessage(it) }
                )
            }
            composable(Screen.Notes.route) {
                NotesScreen(
                    state        = notesState,
                    onSaveNote   = { date, text -> vm.saveHealthNote(date, text) },
                    onDeleteNote = { date -> vm.deleteHealthNote(date) }
                )
            }
            composable(Screen.Credits.route) {
                CreditsScreen(onBack = { navController.popBackStack() })
            }
        }
    }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

@Composable
fun SmartBottomBar(navController: androidx.navigation.NavController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    NavigationBar(
        containerColor = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp
    ) {
        bottomNavScreens.forEach { screen ->
            val selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true

            NavigationBarItem(
                selected = selected,
                onClick  = {
                    navController.navigate(screen.route) {
                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState    = true
                    }
                },
                icon  = {
                    Icon(
                        imageVector        = if (selected) screen.selectedIcon else screen.unselectedIcon,
                        contentDescription = screen.label
                    )
                },
                label = {
                    Text(screen.label, style = MaterialTheme.typography.labelSmall)
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor   = PrimaryGreen,
                    selectedTextColor   = PrimaryGreen,
                    indicatorColor      = PrimaryGreenLight,
                    unselectedIconColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.45f),
                    unselectedTextColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.45f)
                )
            )
        }
    }
}
