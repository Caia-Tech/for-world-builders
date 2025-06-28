package com.caiatech.forworldbuilders.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.ui.viewmodels.WorldDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorldDetailScreen(
    onNavigateBack: () -> Unit,
    onElementClick: (WorldElement) -> Unit,
    onCreateElement: (ElementType) -> Unit,
    onNavigateToNetwork: (() -> Unit)? = null,
    onNavigateToAi: (() -> Unit)? = null,
    viewModel: WorldDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = uiState.world?.title ?: "Loading...",
                            style = MaterialTheme.typography.titleLarge
                        )
                        Text(
                            text = "${uiState.elementCount}/100 elements",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    onNavigateToAi?.let { navigate ->
                        IconButton(onClick = navigate) {
                            Icon(Icons.Default.Star, contentDescription = "AI Assistant")
                        }
                    }
                    onNavigateToNetwork?.let { navigate ->
                        IconButton(onClick = navigate) {
                            Icon(Icons.Default.Share, contentDescription = "Network view")
                        }
                    }
                    IconButton(onClick = { /* TODO: Open world settings */ }) {
                        Icon(Icons.Default.Settings, contentDescription = "World settings")
                    }
                }
            )
        },
        floatingActionButton = {
            if (uiState.canCreateElement) {
                ExtendedFloatingActionButton(
                    onClick = { showCreateDialog = true },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("New Element") }
                )
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search bar
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.updateSearchQuery(it) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search elements...") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                trailingIcon = {
                    if (uiState.searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.updateSearchQuery("") }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear search")
                        }
                    }
                },
                supportingText = if (uiState.searchQuery.isNotEmpty() || uiState.selectedType != null || uiState.showRecentOnly) {
                    { Text("${uiState.filteredElements.size} of ${uiState.elementCount} elements") }
                } else null,
                singleLine = true
            )
            
            // Element type filter chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = uiState.selectedType == null,
                        onClick = { viewModel.selectType(null) },
                        label = { Text("All") },
                        leadingIcon = if (uiState.selectedType == null) {
                            { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                        } else null
                    )
                }
                
                items(ElementType.values().toList()) { type ->
                    val count = uiState.elementsByType[type]?.size ?: 0
                    FilterChip(
                        selected = uiState.selectedType == type,
                        onClick = { viewModel.selectType(type) },
                        label = { Text("${type.name.lowercase().capitalize()} ($count)") },
                        leadingIcon = if (uiState.selectedType == type) {
                            { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                        } else null
                    )
                }
                
                // Add sorting and filter options
                item {
                    var showSortMenu by remember { mutableStateOf(false) }
                    FilterChip(
                        selected = false,
                        onClick = { showSortMenu = true },
                        label = { 
                            Text("Sort: ${uiState.sortBy.name.lowercase().capitalize()}")
                        },
                        leadingIcon = { 
                            Icon(
                                if (uiState.sortOrder == com.caiatech.forworldbuilders.ui.viewmodels.SortOrder.ASC) 
                                    Icons.Default.KeyboardArrowUp 
                                else 
                                    Icons.Default.KeyboardArrowDown, 
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            ) 
                        },
                        trailingIcon = { 
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null, modifier = Modifier.size(16.dp)) 
                        }
                    )
                    
                    DropdownMenu(
                        expanded = showSortMenu,
                        onDismissRequest = { showSortMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Name") },
                            onClick = {
                                viewModel.setSorting(com.caiatech.forworldbuilders.ui.viewmodels.SortBy.NAME)
                                showSortMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Created") },
                            onClick = {
                                viewModel.setSorting(com.caiatech.forworldbuilders.ui.viewmodels.SortBy.CREATED)
                                showSortMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Modified") },
                            onClick = {
                                viewModel.setSorting(com.caiatech.forworldbuilders.ui.viewmodels.SortBy.MODIFIED)
                                showSortMenu = false
                            }
                        )
                        Divider()
                        DropdownMenuItem(
                            text = { Text("Toggle order") },
                            onClick = {
                                viewModel.toggleSortOrder()
                                showSortMenu = false
                            }
                        )
                    }
                }
                
                item {
                    FilterChip(
                        selected = uiState.showRecentOnly,
                        onClick = { viewModel.toggleRecentFilter() },
                        label = { Text("Recent") },
                        leadingIcon = if (uiState.showRecentOnly) {
                            { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                        } else null
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Elements list - use filtered elements
            val displayElements = uiState.filteredElements
            
            if (displayElements.isEmpty()) {
                // Empty state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            when (uiState.selectedType) {
                                ElementType.CHARACTER -> Icons.Default.Person
                                ElementType.LOCATION -> Icons.Default.Place
                                ElementType.EVENT -> Icons.Default.DateRange
                                else -> Icons.Default.Star
                            },
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = if (uiState.searchQuery.isNotEmpty()) {
                                "No elements found"
                            } else {
                                "No ${uiState.selectedType?.name?.lowercase() ?: "elements"} yet"
                            },
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        if (uiState.searchQuery.isEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Button(onClick = { showCreateDialog = true }) {
                                Text("Create First Element")
                            }
                        }
                    }
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(displayElements, key = { it.id }) { element ->
                        ElementCard(
                            element = element,
                            onClick = { onElementClick(element) },
                            onDelete = { viewModel.deleteElement(element) }
                        )
                    }
                }
            }
        }
        
        // Create element dialog
        if (showCreateDialog) {
            CreateElementDialog(
                onDismiss = { showCreateDialog = false },
                onCreate = { type ->
                    onCreateElement(type)
                    showCreateDialog = false
                }
            )
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

@Composable
fun ElementCard(
    element: WorldElement,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var showDeleteDialog by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Element type icon
            Icon(
                imageVector = when (element.type) {
                    ElementType.CHARACTER -> Icons.Default.Person
                    ElementType.LOCATION -> Icons.Default.Place
                    ElementType.EVENT -> Icons.Default.DateRange
                    ElementType.ORGANIZATION -> Icons.Default.AccountCircle
                    ElementType.ITEM -> Icons.Default.ShoppingCart
                    ElementType.CULTURE -> Icons.Default.Favorite
                    ElementType.LANGUAGE -> Icons.Default.Email
                    ElementType.TIMELINE -> Icons.Default.DateRange
                    ElementType.PLOT -> Icons.Default.List
                    ElementType.CONCEPT -> Icons.Default.Star
                    ElementType.CUSTOM -> Icons.Default.MoreVert
                },
                contentDescription = element.type.name,
                modifier = Modifier.size(40.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Element details
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = element.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = element.type.name.lowercase().capitalize(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (element.tags.isNotEmpty()) {
                    Text(
                        text = element.tags,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            
            // Delete button
            IconButton(onClick = { showDeleteDialog = true }) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Delete element",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
    
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Element?") },
            text = { Text("Are you sure you want to delete \"${element.title}\"? This will also delete all relationships involving this element.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun CreateElementDialog(
    onDismiss: () -> Unit,
    onCreate: (ElementType) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Choose Element Type") },
        text = {
            LazyColumn {
                items(ElementType.values().toList()) { type ->
                    ListItem(
                        headlineContent = { Text(type.name.lowercase().capitalize()) },
                        leadingContent = {
                            Icon(
                                imageVector = when (type) {
                                    ElementType.CHARACTER -> Icons.Default.Person
                                    ElementType.LOCATION -> Icons.Default.Place
                                    ElementType.EVENT -> Icons.Default.DateRange
                                    ElementType.ORGANIZATION -> Icons.Default.AccountCircle
                                    ElementType.ITEM -> Icons.Default.ShoppingCart
                                    ElementType.CULTURE -> Icons.Default.Favorite
                                    ElementType.LANGUAGE -> Icons.Default.Email
                                    ElementType.TIMELINE -> Icons.Default.DateRange
                                    ElementType.PLOT -> Icons.Default.List
                                    ElementType.CONCEPT -> Icons.Default.Star
                                    ElementType.CUSTOM -> Icons.Default.MoreVert
                                },
                                contentDescription = null
                            )
                        },
                        modifier = Modifier.clickable { onCreate(type) }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}