package com.caiatech.forworldbuilders.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.ui.viewmodels.ElementDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ElementDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToElement: (String) -> Unit,
    viewModel: ElementDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showAddRelationshipDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = uiState.element?.title ?: "Loading...",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (uiState.element != null) {
                        IconButton(onClick = { viewModel.toggleEditMode() }) {
                            Icon(
                                if (uiState.isEditing) Icons.Default.Close else Icons.Default.Edit,
                                contentDescription = if (uiState.isEditing) "Cancel edit" else "Edit"
                            )
                        }
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "Delete",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        uiState.element?.let { element ->
            if (uiState.isEditing) {
                ElementEditContent(
                    element = element,
                    onSave = { title, content, tags ->
                        viewModel.updateElement(title, content, tags)
                    },
                    onCancel = { viewModel.toggleEditMode() },
                    modifier = Modifier.padding(paddingValues)
                )
            } else {
                ElementDetailContent(
                    element = element,
                    relationships = uiState.relationships,
                    relatedElements = uiState.relatedElements,
                    onRelationshipClick = { relatedElementId ->
                        onNavigateToElement(relatedElementId)
                    },
                    onAddRelationship = { showAddRelationshipDialog = true },
                    onDeleteRelationship = { relationship ->
                        viewModel.deleteRelationship(relationship)
                    },
                    modifier = Modifier.padding(paddingValues)
                )
            }
        } ?: Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }
    
    // Add relationship dialog
    if (showAddRelationshipDialog) {
        AddRelationshipDialog(
            availableElements = uiState.availableElements,
            onDismiss = { showAddRelationshipDialog = false },
            onCreateRelationship = { targetElement, type, strength, description, bidirectional ->
                viewModel.createRelationship(
                    targetElementId = targetElement.id,
                    type = type,
                    strength = strength,
                    description = description,
                    bidirectional = bidirectional
                )
                showAddRelationshipDialog = false
            }
        )
    }
    
    // Delete confirmation dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Element?") },
            text = { 
                Text("Are you sure you want to delete \"${uiState.element?.title}\"? This will also delete all relationships involving this element.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteElement()
                        showDeleteDialog = false
                        onNavigateBack()
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
fun ElementDetailContent(
    element: WorldElement,
    relationships: List<Relationship>,
    relatedElements: Map<String, WorldElement>,
    onRelationshipClick: (String) -> Unit,
    onAddRelationship: () -> Unit,
    onDeleteRelationship: (Relationship) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Element info card
        item {
            Card {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = element.type.name.lowercase().replaceFirstChar { it.uppercase() },
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Text(
                                text = element.title,
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        // Element type icon
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = getIconForElementType(element.type),
                                contentDescription = element.type.name,
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                    
                    if (element.tags.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                Icons.Default.Star,
                                contentDescription = "Tags",
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = element.tags,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
        
        // Content
        item {
            Card {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Details",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = element.content,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
        
        // Relationships section
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Relationships",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                IconButton(onClick = onAddRelationship) {
                    Icon(Icons.Default.Add, contentDescription = "Add relationship")
                }
            }
        }
        
        if (relationships.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                Icons.Default.Share,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "No relationships yet",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        } else {
            items(relationships) { relationship ->
                RelationshipCard(
                    relationship = relationship,
                    currentElementId = element.id,
                    relatedElements = relatedElements,
                    onClick = {
                        val targetId = if (relationship.sourceElementId == element.id) {
                            relationship.targetElementId
                        } else {
                            relationship.sourceElementId
                        }
                        onRelationshipClick(targetId)
                    },
                    onDelete = { onDeleteRelationship(relationship) }
                )
            }
        }
    }
}

@Composable
fun ElementEditContent(
    element: WorldElement,
    onSave: (String, String, String) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    var title by remember { mutableStateOf(element.title) }
    var content by remember { mutableStateOf(element.content) }
    var tags by remember { mutableStateOf(element.tags) }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("Name") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            supportingText = { Text("${title.length}/100") },
            isError = title.length > 100
        )
        
        OutlinedTextField(
            value = content,
            onValueChange = { content = it },
            label = { Text("Details") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 5,
            supportingText = { Text("${content.length}/2000") },
            isError = content.length > 2000
        )
        
        OutlinedTextField(
            value = tags,
            onValueChange = { tags = it },
            label = { Text("Tags") },
            placeholder = { Text("Separate with commas") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) {
                Text("Cancel")
            }
            
            Button(
                onClick = { onSave(title, content, tags) },
                modifier = Modifier.weight(1f),
                enabled = title.isNotBlank() && title.length <= 100 && content.length <= 2000
            ) {
                Text("Save Changes")
            }
        }
    }
}

@Composable
fun RelationshipCard(
    relationship: Relationship,
    currentElementId: String,
    relatedElements: Map<String, WorldElement>,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    val targetId = if (relationship.sourceElementId == currentElementId) {
        relationship.targetElementId
    } else {
        relationship.sourceElementId
    }
    
    val relatedElement = relatedElements[targetId]
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
            // Relationship type icon/indicator
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.secondaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "${relationship.strength}",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = relatedElement?.title ?: "Unknown Element",
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = relationship.type,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                if (relationship.description.isNotEmpty()) {
                    Text(
                        text = relationship.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            
            IconButton(onClick = { showDeleteDialog = true }) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Remove relationship",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
    
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Remove Relationship?") },
            text = { Text("Are you sure you want to remove this relationship?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
                    }
                ) {
                    Text("Remove", color = MaterialTheme.colorScheme.error)
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddRelationshipDialog(
    availableElements: List<WorldElement>,
    onDismiss: () -> Unit,
    onCreateRelationship: (WorldElement, String, Int, String, Boolean) -> Unit
) {
    var selectedElement by remember { mutableStateOf<WorldElement?>(null) }
    var relationshipType by remember { mutableStateOf("") }
    var strength by remember { mutableStateOf(5) }
    var description by remember { mutableStateOf("") }
    var bidirectional by remember { mutableStateOf(false) }
    var showElementSelection by remember { mutableStateOf(false) }
    
    val relationshipTypes = listOf(
        "allies", "enemies", "family", "friends", "rivals", 
        "belongs to", "located in", "connected to", "caused by", 
        "leads to", "part of", "rules", "serves", "custom"
    )
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Relationship") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Target element selection
                OutlinedButton(
                    onClick = { showElementSelection = true },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = selectedElement?.title ?: "Select element to relate to",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                
                // Relationship type dropdown
                if (selectedElement != null) {
                    var expandedTypes by remember { mutableStateOf(false) }
                    
                    ExposedDropdownMenuBox(
                        expanded = expandedTypes,
                        onExpandedChange = { expandedTypes = !expandedTypes }
                    ) {
                        OutlinedTextField(
                            value = relationshipType,
                            onValueChange = { },
                            readOnly = true,
                            label = { Text("Relationship Type") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedTypes) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )
                        
                        ExposedDropdownMenu(
                            expanded = expandedTypes,
                            onDismissRequest = { expandedTypes = false }
                        ) {
                            relationshipTypes.forEach { type ->
                                DropdownMenuItem(
                                    text = { Text(type.replaceFirstChar { it.uppercase() }) },
                                    onClick = {
                                        relationshipType = type
                                        expandedTypes = false
                                    }
                                )
                            }
                        }
                    }
                    
                    // Custom relationship type input
                    if (relationshipType == "custom") {
                        OutlinedTextField(
                            value = description,
                            onValueChange = { description = it },
                            label = { Text("Custom relationship") },
                            placeholder = { Text("e.g., mentor of, enemy of") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    
                    // Strength slider
                    Text("Strength: $strength", style = MaterialTheme.typography.labelMedium)
                    Slider(
                        value = strength.toFloat(),
                        onValueChange = { strength = it.toInt() },
                        valueRange = 1f..10f,
                        steps = 8
                    )
                    
                    // Description field
                    if (relationshipType != "custom") {
                        OutlinedTextField(
                            value = description,
                            onValueChange = { description = it },
                            label = { Text("Description (optional)") },
                            placeholder = { Text("Additional details about this relationship") },
                            modifier = Modifier.fillMaxWidth(),
                            maxLines = 2
                        )
                    }
                    
                    // Bidirectional toggle
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = bidirectional,
                            onCheckedChange = { bidirectional = it }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            "Bidirectional relationship",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    selectedElement?.let { element ->
                        onCreateRelationship(
                            element,
                            if (relationshipType == "custom") description else relationshipType,
                            strength,
                            if (relationshipType == "custom") "" else description,
                            bidirectional
                        )
                    }
                },
                enabled = selectedElement != null && relationshipType.isNotBlank()
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
    
    // Element selection dialog
    if (showElementSelection) {
        AlertDialog(
            onDismissRequest = { showElementSelection = false },
            title = { Text("Select Element") },
            text = {
                if (availableElements.isEmpty()) {
                    Text("No other elements available to create relationships with.")
                } else {
                    LazyColumn(
                        modifier = Modifier.heightIn(max = 300.dp)
                    ) {
                        items(availableElements) { element ->
                            ListItem(
                                headlineContent = { Text(element.title) },
                                supportingContent = { 
                                    Text(element.type.name.lowercase().replaceFirstChar { it.uppercase() }) 
                                },
                                leadingContent = {
                                    Icon(
                                        getIconForElementType(element.type),
                                        contentDescription = element.type.name
                                    )
                                },
                                modifier = Modifier.clickable {
                                    selectedElement = element
                                    showElementSelection = false
                                }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showElementSelection = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

fun getIconForElementType(type: ElementType): androidx.compose.ui.graphics.vector.ImageVector {
    return when (type) {
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
    }
}