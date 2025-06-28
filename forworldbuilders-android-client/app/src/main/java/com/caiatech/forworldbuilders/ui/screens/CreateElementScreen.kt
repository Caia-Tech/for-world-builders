package com.caiatech.forworldbuilders.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.ui.viewmodels.WorldDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateElementScreen(
    elementType: ElementType,
    onNavigateBack: () -> Unit,
    viewModel: WorldDetailViewModel = hiltViewModel()
) {
    var title by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }
    var tags by remember { mutableStateOf("") }
    val uiState by viewModel.uiState.collectAsState()
    
    // Get type-specific prompts
    val (contentLabel, contentHint) = when (elementType) {
        ElementType.CHARACTER -> "Character Details" to "Describe appearance, personality, background, motivations..."
        ElementType.LOCATION -> "Location Details" to "Describe geography, atmosphere, notable features, inhabitants..."
        ElementType.EVENT -> "Event Details" to "Describe what happened, when, where, who was involved, consequences..."
        ElementType.ORGANIZATION -> "Organization Details" to "Describe purpose, structure, members, influence..."
        ElementType.ITEM -> "Item Details" to "Describe appearance, properties, origin, significance..."
        ElementType.CULTURE -> "Culture Details" to "Describe customs, beliefs, values, traditions..."
        ElementType.LANGUAGE -> "Language Details" to "Describe sounds, writing system, common phrases, speakers..."
        ElementType.TIMELINE -> "Timeline Details" to "Describe chronology, key dates, period covered..."
        ElementType.PLOT -> "Plot Details" to "Describe story arc, conflicts, resolution..."
        ElementType.CONCEPT -> "Concept Details" to "Describe the idea, how it works, its importance..."
        ElementType.CUSTOM -> "Details" to "Describe this element..."
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New ${elementType.name.lowercase().capitalize()}") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Element count warning if near limit
            if (uiState.elementCount >= 90) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                "Element Limit Warning",
                                style = MaterialTheme.typography.titleSmall,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Text(
                                "You have ${100 - uiState.elementCount} elements remaining in this world",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Title field
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                supportingText = {
                    val remaining = 100 - title.length
                    when {
                        title.isBlank() -> Text("Element name is required")
                        title.length < 2 -> Text("Name must be at least 2 characters")
                        remaining < 10 -> Text("Only $remaining characters left", color = MaterialTheme.colorScheme.error)
                        else -> Text("$remaining characters remaining")
                    }
                },
                isError = title.length > 100 || (title.isNotBlank() && title.length < 2),
                trailingIcon = {
                    when {
                        title.length > 100 -> Icon(Icons.Default.Warning, contentDescription = "Too long", tint = MaterialTheme.colorScheme.error)
                        title.isNotBlank() && title.length >= 2 && title.length <= 100 -> Icon(Icons.Default.Check, contentDescription = "Valid", tint = MaterialTheme.colorScheme.primary)
                        else -> null
                    }
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Content field
            OutlinedTextField(
                value = content,
                onValueChange = { content = it },
                label = { Text(contentLabel) },
                placeholder = { Text(contentHint) },
                modifier = Modifier.fillMaxWidth(),
                minLines = 5,
                supportingText = {
                    val remaining = 2000 - content.length
                    when {
                        content.isBlank() -> Text("Add details about this ${elementType.name.lowercase()}")
                        remaining < 100 -> Text("Only $remaining characters left", color = MaterialTheme.colorScheme.error)
                        else -> Text("$remaining characters remaining")
                    }
                },
                isError = content.length > 2000,
                trailingIcon = {
                    when {
                        content.length > 2000 -> Icon(Icons.Default.Warning, contentDescription = "Too long", tint = MaterialTheme.colorScheme.error)
                        content.isNotBlank() && content.length <= 2000 -> Icon(Icons.Default.Check, contentDescription = "Valid", tint = MaterialTheme.colorScheme.primary)
                        else -> null
                    }
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Tags field
            OutlinedTextField(
                value = tags,
                onValueChange = { tags = it },
                label = { Text("Tags") },
                placeholder = { Text("Separate with commas: hero, magic, forest") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                supportingText = {
                    val tagCount = if (tags.isBlank()) 0 else tags.split(",").filter { it.trim().isNotBlank() }.size
                    when {
                        tags.isBlank() -> Text("Tags help organize and find elements")
                        tagCount == 1 -> Text("1 tag")
                        else -> Text("$tagCount tags")
                    }
                },
                trailingIcon = {
                    if (tags.isNotBlank()) {
                        Icon(Icons.Default.Check, contentDescription = "Has tags", tint = MaterialTheme.colorScheme.primary)
                    } else null
                }
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Create button
            val isValidForm = title.isNotBlank() && 
                             title.length >= 2 && 
                             title.length <= 100 && 
                             content.length <= 2000
            
            Button(
                onClick = {
                    viewModel.createElement(
                        type = elementType,
                        title = title.trim(),
                        content = content.trim(),
                        tags = tags.trim()
                    )
                    onNavigateBack()
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = isValidForm
            ) {
                if (isValidForm) {
                    Icon(Icons.Filled.Check, contentDescription = null)
                } else {
                    Icon(Icons.Default.Warning, contentDescription = null)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    if (isValidForm) 
                        "Create ${elementType.name.lowercase().replaceFirstChar { it.uppercase() }}" 
                    else 
                        "Complete required fields"
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Cancel button
            OutlinedButton(
                onClick = onNavigateBack,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Cancel")
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Tips card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Info,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            "Quick Tips",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        when (elementType) {
                            ElementType.CHARACTER -> "• Give them clear motivations and flaws\n• Consider their role in your story\n• Think about their relationships"
                            ElementType.LOCATION -> "• Include sensory details\n• Consider the history of the place\n• Think about who lives or visits here"
                            ElementType.EVENT -> "• Specify when it happened\n• Note causes and consequences\n• List key participants"
                            else -> "• Be specific and detailed\n• Use tags for easy organization\n• You can always edit later"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
        }
        
        // Error message
        uiState.errorMessage?.let { error ->
            AlertDialog(
                onDismissRequest = { viewModel.clearError() },
                title = { Text("Error") },
                text = { Text(error) },
                confirmButton = {
                    TextButton(onClick = { viewModel.clearError() }) {
                        Text("OK")
                    }
                }
            )
        }
    }
}