package com.caiatech.forworldbuilders.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.hilt.navigation.compose.hiltViewModel
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.ui.viewmodels.SettingsViewModel
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onUpgradeClick: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    var showExportDialog by remember { mutableStateOf(false) }
    
    // File picker for import
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let { 
            readFileContent(context, it) { content ->
                viewModel.importFromJson(content)
            }
        }
    }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            item {
                ListItem(
                    headlineContent = { Text("Free Version") },
                    supportingContent = { Text("3 worlds, 100 elements per world") },
                    leadingContent = {
                        Icon(Icons.Filled.Star, contentDescription = null)
                    }
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Upgrade to Pro") },
                    supportingContent = { Text("Unlimited worlds, AI assistance, and more") },
                    leadingContent = {
                        Icon(Icons.Filled.ShoppingCart, contentDescription = null)
                    },
                    colors = ListItemDefaults.colors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    ),
                    modifier = Modifier.clickable { onUpgradeClick() }
                )
            }
            
            item { 
                Divider(modifier = Modifier.padding(vertical = 8.dp))
            }
            
            // AI Settings section header
            item {
                Text(
                    text = "AI Assistant",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            
            item {
                var showApiKeyDialog by remember { mutableStateOf(false) }
                
                ListItem(
                    headlineContent = { Text("OpenAI API Key") },
                    supportingContent = { 
                        Text(
                            if (uiState.apiKey.isNotBlank()) 
                                "API key configured (${uiState.apiKey.take(8)}...)" 
                            else 
                                "Required for AI features"
                        )
                    },
                    leadingContent = {
                        Icon(Icons.Filled.Lock, contentDescription = null)
                    },
                    trailingContent = {
                        Text(
                            if (uiState.apiKey.isNotBlank()) "Edit" else "Add",
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.labelMedium
                        )
                    },
                    modifier = Modifier.clickable { showApiKeyDialog = true }
                )
                
                if (showApiKeyDialog) {
                    ApiKeyDialog(
                        currentApiKey = uiState.apiKey,
                        onSave = { newApiKey ->
                            viewModel.updateApiKey(newApiKey)
                            showApiKeyDialog = false
                        },
                        onDismiss = { showApiKeyDialog = false }
                    )
                }
            }
            
            item { 
                Divider(modifier = Modifier.padding(vertical = 8.dp))
            }
            
            // Data section header
            item {
                Text(
                    text = "Data Management",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Export Data") },
                    supportingContent = { Text("Export your worlds as JSON") },
                    leadingContent = {
                        Icon(Icons.Filled.Share, contentDescription = null)
                    },
                    modifier = Modifier.clickable { showExportDialog = true }
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Import Data") },
                    supportingContent = { Text("Import worlds from JSON file") },
                    leadingContent = {
                        Icon(Icons.Filled.Add, contentDescription = null)
                    },
                    modifier = Modifier.clickable { 
                        filePickerLauncher.launch(arrayOf("application/json", "text/plain"))
                    }
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Privacy") },
                    supportingContent = { Text("All data stored locally on your device") },
                    leadingContent = {
                        Icon(Icons.Filled.Lock, contentDescription = null)
                    }
                )
            }
            
            item { 
                Divider(modifier = Modifier.padding(vertical = 8.dp))
            }
            
            item {
                ListItem(
                    headlineContent = { Text("About") },
                    supportingContent = { Text("Version 1.0.0") },
                    leadingContent = {
                        Icon(Icons.Filled.Info, contentDescription = null)
                    }
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Website") },
                    supportingContent = { Text("forworldbuilders.com") },
                    leadingContent = {
                        Icon(Icons.Filled.Home, contentDescription = null)
                    }
                )
            }
            
            item {
                ListItem(
                    headlineContent = { Text("Support") },
                    supportingContent = { Text("Get help and report issues") },
                    leadingContent = {
                        Icon(Icons.Filled.Info, contentDescription = null)
                    }
                )
            }
        }
    }
    
    // Export dialog
    if (showExportDialog) {
        ExportDialog(
            worlds = uiState.worlds,
            isExporting = uiState.isExporting,
            onDismiss = { 
                showExportDialog = false
                viewModel.clearExportResult()
            },
            onExportWorld = { world -> viewModel.exportWorld(world) },
            onExportAll = { viewModel.exportAllWorlds() }
        )
    }
    
    // Import conflict dialog
    if (uiState.conflictingWorlds.isNotEmpty()) {
        ImportConflictDialog(
            conflictingWorlds = uiState.conflictingWorlds,
            onOverwrite = { viewModel.confirmImport(true) },
            onSkip = { viewModel.confirmImport(false) },
            onCancel = { viewModel.cancelImport() }
        )
    }
    
    // Handle export result
    LaunchedEffect(uiState.exportResult) {
        uiState.exportResult?.let { jsonData ->
            shareJsonFile(context, jsonData)
            viewModel.clearExportResult()
            showExportDialog = false
        }
    }
    
    // Handle import result
    LaunchedEffect(uiState.importResult) {
        uiState.importResult?.let { result ->
            // TODO: Show success message/snackbar
            viewModel.clearImportResult()
        }
    }
    
    // Show error message
    uiState.errorMessage?.let { error ->
        LaunchedEffect(error) {
            // TODO: Show snackbar or toast with error
        }
    }
    
}

@Composable
fun ExportDialog(
    worlds: List<World>,
    isExporting: Boolean,
    onDismiss: () -> Unit,
    onExportWorld: (World) -> Unit,
    onExportAll: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Export Data") },
        text = {
            if (isExporting) {
                Row(
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(16.dp))
                    Text("Exporting...")
                }
            } else {
                Column {
                    Text("Choose what to export:")
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    if (worlds.isNotEmpty()) {
                        Button(
                            onClick = onExportAll,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Export All Worlds")
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            "Or export individual worlds:",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        LazyColumn(
                            modifier = Modifier.heightIn(max = 200.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            items(worlds) { world ->
                                OutlinedButton(
                                    onClick = { onExportWorld(world) },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        text = world.title,
                                        maxLines = 1,
                                        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                                    )
                                }
                            }
                        }
                    } else {
                        Text(
                            "No worlds to export. Create a world first!",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        },
        confirmButton = {
            if (!isExporting) {
                TextButton(onClick = onDismiss) {
                    Text("Cancel")
                }
            }
        }
    )
}

@Composable
fun ImportConflictDialog(
    conflictingWorlds: List<String>,
    onOverwrite: () -> Unit,
    onSkip: () -> Unit,
    onCancel: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text("Import Conflicts Found") },
        text = {
            Column {
                Text("The following worlds already exist:")
                Spacer(modifier = Modifier.height(8.dp))
                conflictingWorlds.forEach { worldName ->
                    Text(
                        "• $worldName",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text("How would you like to proceed?")
            }
        },
        confirmButton = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TextButton(onClick = onSkip) {
                    Text("Skip Existing")
                }
                Button(onClick = onOverwrite) {
                    Text("Overwrite All")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onCancel) {
                Text("Cancel")
            }
        }
    )
}

private fun shareJsonFile(context: Context, jsonData: String) {
    try {
        val fileName = "forworldbuilders_export_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.json"
        val file = File(context.cacheDir, fileName)
        file.writeText(jsonData)
        
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
        
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/json"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, "For World Builders Export")
            putExtra(Intent.EXTRA_TEXT, "Your world data from For World Builders")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        context.startActivity(Intent.createChooser(shareIntent, "Share Export"))
    } catch (e: Exception) {
        // TODO: Handle error (show toast/snackbar)
    }
}

@Composable
fun ApiKeyDialog(
    currentApiKey: String,
    onSave: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var apiKey by remember { mutableStateOf(currentApiKey) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("OpenAI API Key") },
        text = {
            Column {
                Text(
                    "Enter your OpenAI API key to enable AI features. Your key is stored securely on your device.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = apiKey,
                    onValueChange = { apiKey = it },
                    label = { Text("API Key") },
                    placeholder = { Text("sk-...") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 1
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = { 
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://platform.openai.com/api-keys"))
                            onDismiss()
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Get API Key", style = MaterialTheme.typography.labelMedium)
                    }
                    
                    if (currentApiKey.isNotBlank()) {
                        OutlinedButton(
                            onClick = { 
                                onSave("")
                                onDismiss()
                            },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Remove", style = MaterialTheme.typography.labelMedium)
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onSave(apiKey.trim()) },
                enabled = apiKey.trim().isNotEmpty()
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}


private fun readFileContent(context: Context, uri: Uri, onContent: (String) -> Unit) {
    try {
        context.contentResolver.openInputStream(uri)?.use { inputStream ->
            val content = inputStream.bufferedReader().use { it.readText() }
            onContent(content)
        }
    } catch (e: Exception) {
        // TODO: Handle error (show toast/snackbar)
    }
}
