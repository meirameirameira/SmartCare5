package com.smarthas.smartcare.ui.screens

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreditsScreen(onBack: () -> Unit) {
    Column(modifier = Modifier.fillMaxSize()) {

        // ── Top Bar ──────────────────────────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.linearGradient(
                        colors = listOf(PrimaryGreen, PrimaryGreenDark),
                        start  = Offset(0f, 0f),
                        end    = Offset(Float.POSITIVE_INFINITY, 0f)
                    )
                )
                .statusBarsPadding()
                .padding(horizontal = 4.dp, vertical = 4.dp)
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector        = Icons.Filled.ArrowBack,
                    contentDescription = "Voltar",
                    tint               = Color.White
                )
            }
            Text(
                text      = "Créditos",
                style     = MaterialTheme.typography.titleMedium,
                color     = Color.White,
                fontWeight = FontWeight.SemiBold,
                modifier  = Modifier.align(Alignment.Center)
            )
        }

        // ── Body ─────────────────────────────────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(28.dp))

            // App identity
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(PrimaryGreen, PrimaryGreenDark)
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text("💚", fontSize = 36.sp)
            }
            Spacer(Modifier.height(12.dp))
            Text(
                "SmartCare 5.0",
                style      = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color      = PrimaryGreenDark
            )
            Text(
                "v5.0.0  •  2025",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
            )

            Spacer(Modifier.height(8.dp))
            Text(
                "Apoio ao autocuidado e prevencao em saude,\nalinhado a Sociedade 5.0.",
                style     = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color     = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )

            Spacer(Modifier.height(28.dp))

            // Developers section
            CreditsSection(title = "Equipe Desenvolvedora") {
                DeveloperCard(emoji = "👤", name = "Felipe Meira Macedo",  rm = "RM 555789")
                DeveloperCard(emoji = "👤", name = "Flavio Fujita",         rm = "RM 555085")
                DeveloperCard(emoji = "👤", name = "Guilherme do Amaral",  rm = "RM 556376")
                DeveloperCard(emoji = "👤", name = "Gustavo Serafim",      rm = "RM 558538")
            }

            Spacer(Modifier.height(16.dp))

            // Technologies section
            CreditsSection(title = "Tecnologias Utilizadas") {
                TechRow("📱", "Kotlin + Jetpack Compose",         "Android")
                TechRow("🏛️", "MVVM + StateFlow + Coroutines",    "Arquitetura")
                TechRow("🧭", "Navigation Compose",               "Navegacao")
                TechRow("💾", "SharedPreferences",                "Persistencia Local")
                TechRow("🌐", "Retrofit + OkHttp",                "API REST")
                TechRow("🎨", "Material Design 3",                "UI/UX")
                TechRow("🤖", "IA Generativa (LLM)",              "Assistente de Saude")
                TechRow("📊", "Random Forest / XGBoost (ML)",     "Predicao de Espera")
            }

            Spacer(Modifier.height(16.dp))

            // Institution section
            CreditsSection(title = "Instituicao") {
                InfoRow("🎓", "FIAP", "Faculdade de Informatica e Administracao Paulista")
                InfoRow("📚", "Curso", "Engenharia de Software")
                InfoRow("🏆", "Parceiro", "Enterprise Challenge - Leroy Merlin")
            }

            Spacer(Modifier.height(16.dp))

            // Society 5.0 badge
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape    = RoundedCornerShape(16.dp),
                color    = PrimaryGreenLight
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text("🌍", fontSize = 28.sp)
                    Column {
                        Text(
                            "Alinhado a Sociedade 5.0",
                            style      = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color      = PrimaryGreenDark
                        )
                        Text(
                            "Tecnologia centrada no ser humano para resolver desafios sociais reais de saude e bem-estar.",
                            style = MaterialTheme.typography.bodySmall,
                            color = PrimaryGreenDark.copy(alpha = 0.75f)
                        )
                    }
                }
            }

            Spacer(Modifier.height(32.dp))

            Text(
                "SMART HAS Team © 2025",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)
            )
            Spacer(Modifier.height(16.dp))
        }
    }
}

// ─── Helper composables ───────────────────────────────────────────────────────

@Composable
private fun CreditsSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape    = RoundedCornerShape(16.dp),
        color    = MaterialTheme.colorScheme.surface,
        border   = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                title,
                style      = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color      = PrimaryGreen
            )
            Spacer(Modifier.height(12.dp))
            content()
        }
    }
}

@Composable
private fun DeveloperCard(emoji: String, name: String, rm: String) {
    Row(
        modifier          = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier         = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(PrimaryGreenLight),
            contentAlignment = Alignment.Center
        ) { Text(emoji, fontSize = 18.sp) }
        Column(modifier = Modifier.weight(1f)) {
            Text(name, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            Text(rm,   style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
        }
    }
}

@Composable
private fun TechRow(icon: String, name: String, category: String) {
    Row(
        modifier          = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(icon, fontSize = 16.sp, modifier = Modifier.width(24.dp))
        Text(
            name,
            style    = MaterialTheme.typography.bodySmall,
            modifier = Modifier.weight(1f)
        )
        Surface(
            shape = RoundedCornerShape(6.dp),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Text(
                category,
                style    = MaterialTheme.typography.labelSmall,
                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                color    = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun InfoRow(icon: String, label: String, value: String) {
    Row(
        modifier          = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(icon,  fontSize = 16.sp, modifier = Modifier.width(24.dp))
        Text(label, style = MaterialTheme.typography.bodySmall,
             fontWeight = FontWeight.Medium, modifier = Modifier.width(72.dp))
        Text(value, style = MaterialTheme.typography.bodySmall,
             color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
             modifier = Modifier.weight(1f))
    }
}
