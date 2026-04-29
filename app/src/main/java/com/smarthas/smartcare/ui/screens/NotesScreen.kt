package com.smarthas.smartcare.ui.screens

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.shape.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.NoteAdd
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.ui.components.SmartTopBar
import com.smarthas.smartcare.ui.components.SectionLabel
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.NotesUiState
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun NotesScreen(
    state: NotesUiState,
    onSaveNote: (date: String, text: String) -> Unit,
    onDeleteNote: (date: String) -> Unit
) {
    val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)

    var inputText by remember { mutableStateOf(state.noteForToday ?: "") }
    var showSnackbar by remember { mutableStateOf(false) }

    LaunchedEffect(state.noteForToday) {
        inputText = state.noteForToday ?: ""
    }

    Column(modifier = Modifier.fillMaxSize()) {

        SmartTopBar(
            greeting     = "Registros de",
            title        = "Saude Diaria",
            trailingIcon = "📝",
            badge        = 0
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(Modifier.height(16.dp))

            // ── Today's note card ─────────────────────────────────────────
            SectionLabel("nota de hoje")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape    = RoundedCornerShape(16.dp),
                color    = MaterialTheme.colorScheme.surface,
                border   = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        today,
                        style = MaterialTheme.typography.labelMedium,
                        color = PrimaryGreen,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value         = inputText,
                        onValueChange = { inputText = it },
                        modifier      = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 100.dp),
                        placeholder   = {
                            Text(
                                "Como voce esta se sentindo hoje? Registre sintomas, humor ou observacoes...",
                                style = MaterialTheme.typography.bodySmall
                            )
                        },
                        shape  = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor   = PrimaryGreen,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        )
                    )
                    Spacer(Modifier.height(10.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (!state.noteForToday.isNullOrBlank()) {
                            TextButton(
                                onClick = {
                                    onDeleteNote(today)
                                    inputText = ""
                                }
                            ) {
                                Icon(
                                    Icons.Filled.Delete, null,
                                    tint     = MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(Modifier.width(4.dp))
                                Text("Apagar", color = MaterialTheme.colorScheme.error,
                                     style = MaterialTheme.typography.labelMedium)
                            }
                        }
                        Spacer(Modifier.weight(1f))
                        Button(
                            onClick = {
                                if (inputText.isNotBlank()) {
                                    onSaveNote(today, inputText)
                                    showSnackbar = true
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryGreen),
                            shape  = RoundedCornerShape(10.dp)
                        ) {
                            Icon(Icons.Filled.Save, null, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("Salvar nota")
                        }
                    }
                    if (showSnackbar) {
                        Spacer(Modifier.height(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = PrimaryGreenLight
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(Icons.Filled.CheckCircle, null,
                                     tint = PrimaryGreenDark, modifier = Modifier.size(16.dp))
                                Text("Nota salva localmente!",
                                     style = MaterialTheme.typography.bodySmall,
                                     color = PrimaryGreenDark)
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(20.dp))

            // ── Notes history ─────────────────────────────────────────────
            if (state.allNotes.isNotEmpty()) {
                SectionLabel("historico de notas (${state.allNotes.size})")

                state.allNotes
                    .entries
                    .sortedByDescending { it.key }
                    .filter  { it.key != today }
                    .forEach { (date, note) ->
                        NoteHistoryItem(
                            date     = date,
                            note     = note,
                            onDelete = { onDeleteNote(date) }
                        )
                        Spacer(Modifier.height(8.dp))
                    }
            } else {
                // Empty state
                Column(
                    modifier            = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("📝", fontSize = 40.sp)
                    Text(
                        "Nenhuma nota anterior",
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        "Comece registrando como voce se sente hoje.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                    )
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun NoteHistoryItem(date: String, note: String, onDelete: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Surface(
        onClick  = { expanded = !expanded },
        modifier = Modifier.fillMaxWidth(),
        shape    = RoundedCornerShape(12.dp),
        color    = MaterialTheme.colorScheme.surface,
        border   = BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier              = Modifier.fillMaxWidth()
            ) {
                Row(
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier         = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(PrimaryGreenLight),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("📅", fontSize = 14.sp)
                    }
                    Column {
                        Text(date,
                             style = MaterialTheme.typography.labelMedium,
                             fontWeight = FontWeight.SemiBold)
                        Text(
                            note.take(40) + if (note.length > 40) "..." else "",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
                        )
                    }
                }
                Row {
                    if (expanded) {
                        IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                            Icon(Icons.Filled.Delete, null,
                                 tint     = MaterialTheme.colorScheme.error,
                                 modifier = Modifier.size(16.dp))
                        }
                    }
                    Icon(
                        if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                        contentDescription = null,
                        tint     = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            if (expanded) {
                Spacer(Modifier.height(10.dp))
                HorizontalDivider(color = MaterialTheme.colorScheme.outline)
                Spacer(Modifier.height(10.dp))
                Text(note, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
