package com.caiatech.forworldbuilders.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.ui.viewmodels.LayoutAlgorithm
import com.caiatech.forworldbuilders.ui.viewmodels.NetworkNode
import com.caiatech.forworldbuilders.ui.viewmodels.NetworkEdge
import com.caiatech.forworldbuilders.ui.viewmodels.NetworkViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NetworkScreen(
    onNavigateBack: () -> Unit,
    onElementClick: (WorldElement) -> Unit,
    viewModel: NetworkViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showControls by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(uiState.world?.title?.let { "$it - Network View" } ?: "Network View") 
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.toggleLabels() }) {
                        Icon(
                            Icons.Default.Star,
                            contentDescription = "Toggle labels"
                        )
                    }
                    IconButton(onClick = { showControls = !showControls }) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (showControls) {
                NetworkControls(
                    selectedType = uiState.selectedType,
                    layoutAlgorithm = uiState.layoutAlgorithm,
                    onTypeFilter = { viewModel.filterByType(it) },
                    onLayoutChange = { viewModel.setLayoutAlgorithm(it) }
                )
            }
            
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Building network...")
                    }
                }
            } else if (uiState.nodes.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Share,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "No elements to visualize",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            "Create some elements and relationships first",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                NetworkVisualization(
                    nodes = uiState.nodes,
                    edges = uiState.edges,
                    showLabels = uiState.showLabels,
                    onNodeClick = { node ->
                        viewModel.selectElement(node.element)
                        onElementClick(node.element)
                    },
                    modifier = Modifier.weight(1f)
                )
            }
            
            // Selected element info
            uiState.selectedElement?.let { element ->
                SelectedElementInfo(
                    element = element,
                    connections = uiState.nodes.find { it.element.id == element.id }?.connections ?: 0,
                    onDismiss = { viewModel.selectElement(null) }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NetworkControls(
    selectedType: ElementType?,
    layoutAlgorithm: LayoutAlgorithm,
    onTypeFilter: (ElementType?) -> Unit,
    onLayoutChange: (LayoutAlgorithm) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                "Network Controls",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Layout algorithm selection
            Text("Layout Algorithm:", style = MaterialTheme.typography.labelMedium)
            Spacer(modifier = Modifier.height(4.dp))
            
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(LayoutAlgorithm.values()) { algorithm ->
                    FilterChip(
                        selected = layoutAlgorithm == algorithm,
                        onClick = { onLayoutChange(algorithm) },
                        label = { 
                            Text(when (algorithm) {
                                LayoutAlgorithm.CIRCULAR -> "Circular"
                                LayoutAlgorithm.FORCE_DIRECTED -> "Force"
                                LayoutAlgorithm.HIERARCHICAL -> "Hierarchy"
                            })
                        }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Type filter
            Text("Filter by Type:", style = MaterialTheme.typography.labelMedium)
            Spacer(modifier = Modifier.height(4.dp))
            
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedType == null,
                        onClick = { onTypeFilter(null) },
                        label = { Text("All") }
                    )
                }
                items(ElementType.values()) { type ->
                    FilterChip(
                        selected = selectedType == type,
                        onClick = { onTypeFilter(type) },
                        label = { Text(type.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }
        }
    }
}

@Composable
fun NetworkVisualization(
    nodes: List<NetworkNode>,
    edges: List<NetworkEdge>,
    showLabels: Boolean,
    onNodeClick: (NetworkNode) -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    
    Canvas(
        modifier = modifier
            .fillMaxSize()
            .clipToBounds()
            .clickable { /* Handle canvas clicks */ }
    ) {
        // Draw edges first (so they appear behind nodes)
        edges.forEach { edge ->
            drawEdge(edge)
        }
        
        // Draw nodes
        nodes.forEach { node ->
            drawNode(node, showLabels, density)
        }
    }
}

private fun DrawScope.drawEdge(edge: NetworkEdge) {
    val start = Offset(edge.startNode.x, edge.startNode.y)
    val end = Offset(edge.endNode.x, edge.endNode.y)
    
    // Edge color based on relationship strength
    val alpha = (edge.strength * 0.8f + 0.2f) // Ensure minimum visibility
    val color = Color.Gray.copy(alpha = alpha)
    
    // Edge thickness based on strength
    val strokeWidth = edge.strength * 8f + 1f
    
    drawLine(
        color = color,
        start = start,
        end = end,
        strokeWidth = strokeWidth
    )
}

private fun DrawScope.drawNode(
    node: NetworkNode,
    showLabels: Boolean,
    density: androidx.compose.ui.unit.Density
) {
    val position = Offset(node.x, node.y)
    
    // Node size based on connection count
    val baseRadius = 20f
    val sizeMultiplier = (node.connections * 0.3f + 1f).coerceAtMost(3f)
    val radius = baseRadius * sizeMultiplier
    
    // Node color based on element type
    val nodeColor = getElementTypeColor(node.element.type)
    val strokeColor = if (node.isSelected) Color.Red else Color.Black
    
    // Draw node background
    drawCircle(
        color = nodeColor,
        radius = radius,
        center = position
    )
    
    // Draw node border
    drawCircle(
        color = strokeColor,
        radius = radius,
        center = position,
        style = androidx.compose.ui.graphics.drawscope.Stroke(width = if (node.isSelected) 4f else 2f)
    )
    
    // Simple connection count visualization using smaller circle
    if (node.connections > 0) {
        drawCircle(
            color = Color.White,
            radius = 8f,
            center = Offset(position.x + radius * 0.7f, position.y - radius * 0.7f)
        )
        drawCircle(
            color = Color.Black,
            radius = 8f,
            center = Offset(position.x + radius * 0.7f, position.y - radius * 0.7f),
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 1f)
        )
    }
}

private fun getElementTypeColor(type: ElementType): Color {
    return when (type) {
        ElementType.CHARACTER -> Color(0xFFE57373) // Red
        ElementType.LOCATION -> Color(0xFF81C784) // Green
        ElementType.EVENT -> Color(0xFF64B5F6) // Blue
        ElementType.ORGANIZATION -> Color(0xFFBA68C8) // Purple
        ElementType.ITEM -> Color(0xFFFFB74D) // Orange
        ElementType.CULTURE -> Color(0xFF4DB6AC) // Teal
        ElementType.LANGUAGE -> Color(0xFF9575CD) // Deep Purple
        ElementType.TIMELINE -> Color(0xFF7986CB) // Indigo
        ElementType.PLOT -> Color(0xFFF06292) // Pink
        ElementType.CONCEPT -> Color(0xFF90A4AE) // Blue Grey
        ElementType.CUSTOM -> Color(0xFFA1887F) // Brown
    }
}

@Composable
fun SelectedElementInfo(
    element: WorldElement,
    connections: Int,
    onDismiss: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    element.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    element.type.name.lowercase().replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    "$connections connections",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
            
            IconButton(onClick = onDismiss) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Dismiss",
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}