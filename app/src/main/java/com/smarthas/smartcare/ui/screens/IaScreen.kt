package com.smarthas.smartcare.ui.screens

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.shape.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.*
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.*
import com.smarthas.smartcare.data.model.*
import com.smarthas.smartcare.ui.components.*
import com.smarthas.smartcare.ui.theme.*
import com.smarthas.smartcare.viewmodel.ChatUiState

@Composable
fun IaScreen(
    state: ChatUiState,
    onSendMessage: (String) -> Unit
) {
    var inputText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    val keyboard  = LocalSoftwareKeyboardController.current

    // Auto-scroll to bottom when new messages arrive
    LaunchedEffect(state.messages.size) {
        if (state.messages.isNotEmpty()) {
            listState.animateScrollToItem(state.messages.size - 1)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {

        SmartTopBar(
            greeting     = "Assistente clínico",
            title        = "IA SmartCare",
            trailingIcon = "🤖"
        )

        // Message list
        LazyColumn(
            state          = listState,
            modifier       = Modifier
                .weight(1f)
                .background(MaterialTheme.colorScheme.background),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(state.messages) { message ->
                when (message.role) {
                    MessageRole.AI   -> AiMessageBubble(message)
                    MessageRole.USER -> UserMessageBubble(message)
                }
            }

            // Quick prompts (shown after initial messages)
            if (state.messages.size <= 2 && state.quickPrompts.isNotEmpty()) {
                item {
                    Spacer(Modifier.height(4.dp))
                    FlowRowPrompts(prompts = state.quickPrompts, onSelect = onSendMessage)
                }
            }

            // Typing indicator
            if (state.isTyping) {
                item { TypingIndicator() }
            }
        }

        // Input area
        ChatInputBar(
            value      = inputText,
            onValueChange = { inputText = it },
            onSend     = {
                if (inputText.isNotBlank()) {
                    onSendMessage(inputText)
                    inputText = ""
                    keyboard?.hide()
                }
            }
        )
    }
}

// ─── AI Message Bubble ────────────────────────────────────────────────────────

@Composable
private fun AiMessageBubble(message: ChatMessage) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment     = Alignment.Bottom,
        modifier              = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier         = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(PrimaryGreenLight),
            contentAlignment = Alignment.Center
        ) {
            Text("🤖", fontSize = 14.sp)
        }

        Column(modifier = Modifier.widthIn(max = 290.dp)) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(topStart = 4.dp, topEnd = 16.dp, bottomEnd = 16.dp, bottomStart = 16.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .border(0.5.dp, MaterialTheme.colorScheme.outline,
                            RoundedCornerShape(topStart = 4.dp, topEnd = 16.dp, bottomEnd = 16.dp, bottomStart = 16.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            ) {
                Column {
                    Text(
                        text  = message.content,
                        style = MaterialTheme.typography.bodyMedium,
                        lineHeight = 22.sp
                    )
                    Text(
                        text  = message.timeLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
                        modifier = Modifier.align(Alignment.End).padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

// ─── User Message Bubble ─────────────────────────────────────────────────────

@Composable
private fun UserMessageBubble(message: ChatMessage) {
    Row(
        modifier              = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.End
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 290.dp)
                .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 4.dp, bottomEnd = 16.dp, bottomStart = 16.dp))
                .background(PrimaryGreen)
                .padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            Text(
                text  = message.content,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White,
                lineHeight = 22.sp
            )
        }
    }
}

// ─── Quick Prompts ────────────────────────────────────────────────────────────

@Composable
private fun FlowRowPrompts(prompts: List<QuickPrompt>, onSelect: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        // Row 1
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            prompts.take(3).forEach { prompt ->
                SmartChip(
                    text      = prompt.label,
                    chipColor = prompt.chipColor,
                    onClick   = { onSelect(prompt.message) }
                )
            }
        }
        // Row 2
        if (prompts.size > 3) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                prompts.drop(3).forEach { prompt ->
                    SmartChip(
                        text      = prompt.label,
                        chipColor = prompt.chipColor,
                        onClick   = { onSelect(prompt.message) }
                    )
                }
            }
        }
    }
}

// ─── Typing Indicator ────────────────────────────────────────────────────────

@Composable
private fun TypingIndicator() {
    Row(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Box(
            modifier         = Modifier.size(32.dp).clip(CircleShape).background(PrimaryGreenLight),
            contentAlignment = Alignment.Center
        ) { Text("🤖", fontSize = 14.sp) }

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(topStart = 4.dp, topEnd = 16.dp, bottomEnd = 16.dp, bottomStart = 16.dp))
                .background(MaterialTheme.colorScheme.surface)
                .border(0.5.dp, MaterialTheme.colorScheme.outline,
                        RoundedCornerShape(topStart = 4.dp, topEnd = 16.dp, bottomEnd = 16.dp, bottomStart = 16.dp))
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                repeat(3) { i ->
                    Box(modifier = Modifier.size(6.dp).clip(CircleShape)
                        .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f + i * 0.1f)))
                }
            }
        }
    }
}

// ─── Chat Input Bar ───────────────────────────────────────────────────────────

@Composable
private fun ChatInputBar(
    value: String,
    onValueChange: (String) -> Unit,
    onSend: () -> Unit
) {
    Surface(
        modifier      = Modifier.fillMaxWidth(),
        color         = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp,
        shadowElevation = 0.dp
    ) {
        HorizontalDivider(color = MaterialTheme.colorScheme.outline, thickness = 0.5.dp)
        Row(
            modifier              = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment     = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value         = value,
                onValueChange = onValueChange,
                placeholder   = {
                    Text("Pergunte sobre sua saúde...",
                         style = MaterialTheme.typography.bodyMedium,
                         color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f))
                },
                modifier      = Modifier.weight(1f),
                shape         = RoundedCornerShape(24.dp),
                maxLines      = 3,
                singleLine    = false,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                keyboardActions = KeyboardActions(onSend = { onSend() }),
                colors        = OutlinedTextFieldDefaults.colors(
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    focusedBorderColor   = PrimaryGreen
                )
            )

            FilledIconButton(
                onClick  = onSend,
                modifier = Modifier.size(44.dp),
                colors   = IconButtonDefaults.filledIconButtonColors(containerColor = PrimaryGreen)
            ) {
                Icon(Icons.Filled.Send, contentDescription = "Enviar",
                     tint = Color.White, modifier = Modifier.size(18.dp))
            }
        }
    }
}
