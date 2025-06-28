package com.caiatech.forworldbuilders.ui.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.data.repository.WorldBuildingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.math.*

data class NetworkNode(
    val element: WorldElement,
    val x: Float,
    val y: Float,
    val connections: Int,
    val isSelected: Boolean = false
)

data class NetworkEdge(
    val relationship: Relationship,
    val startNode: NetworkNode,
    val endNode: NetworkNode,
    val strength: Float = relationship.strength / 10f // Normalize to 0-1
)

data class NetworkUiState(
    val world: World? = null,
    val nodes: List<NetworkNode> = emptyList(),
    val edges: List<NetworkEdge> = emptyList(),
    val selectedElement: WorldElement? = null,
    val selectedType: ElementType? = null,
    val isLoading: Boolean = false,
    val showLabels: Boolean = true,
    val layoutAlgorithm: LayoutAlgorithm = LayoutAlgorithm.FORCE_DIRECTED
)

enum class LayoutAlgorithm {
    CIRCULAR, FORCE_DIRECTED, HIERARCHICAL
}

@HiltViewModel
class NetworkViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: WorldBuildingRepository
) : ViewModel() {
    
    private val worldId: String = savedStateHandle.get<String>("worldId") ?: ""
    
    private val _uiState = MutableStateFlow(NetworkUiState())
    val uiState: StateFlow<NetworkUiState> = _uiState.asStateFlow()
    
    init {
        loadNetworkData()
    }
    
    private fun loadNetworkData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            val world = repository.getWorldById(worldId)
            
            repository.getElementsForWorld(worldId).collect { elements ->
                val relationships = repository.getRelationshipsForWorld(worldId)
                
                // Calculate network layout
                val nodes = calculateNodeLayout(elements, relationships)
                val edges = createEdges(relationships, nodes)
                
                _uiState.update { 
                    it.copy(
                        world = world,
                        nodes = nodes,
                        edges = edges,
                        isLoading = false
                    )
                }
            }
        }
    }
    
    private fun calculateNodeLayout(elements: List<WorldElement>, relationships: List<Relationship>): List<NetworkNode> {
        if (elements.isEmpty()) return emptyList()
        
        // Count connections for each element
        val connectionCounts = mutableMapOf<String, Int>()
        relationships.forEach { relationship ->
            connectionCounts[relationship.sourceElementId] = (connectionCounts[relationship.sourceElementId] ?: 0) + 1
            connectionCounts[relationship.targetElementId] = (connectionCounts[relationship.targetElementId] ?: 0) + 1
        }
        
        return when (_uiState.value.layoutAlgorithm) {
            LayoutAlgorithm.CIRCULAR -> calculateCircularLayout(elements, connectionCounts)
            LayoutAlgorithm.FORCE_DIRECTED -> calculateForceDirectedLayout(elements, relationships, connectionCounts)
            LayoutAlgorithm.HIERARCHICAL -> calculateHierarchicalLayout(elements, connectionCounts)
        }
    }
    
    private fun calculateCircularLayout(elements: List<WorldElement>, connectionCounts: Map<String, Int>): List<NetworkNode> {
        val centerX = 500f
        val centerY = 500f
        val radius = 300f
        
        return elements.mapIndexed { index, element ->
            val angle = (2 * PI * index / elements.size).toFloat()
            val x = centerX + radius * cos(angle)
            val y = centerY + radius * sin(angle)
            
            NetworkNode(
                element = element,
                x = x,
                y = y,
                connections = connectionCounts[element.id] ?: 0
            )
        }
    }
    
    private fun calculateForceDirectedLayout(
        elements: List<WorldElement>, 
        relationships: List<Relationship>,
        connectionCounts: Map<String, Int>
    ): List<NetworkNode> {
        val width = 1000f
        val height = 1000f
        
        // Initialize random positions
        val positions = mutableMapOf<String, Pair<Float, Float>>()
        elements.forEach { element ->
            positions[element.id] = Pair(
                (Math.random() * width).toFloat(),
                (Math.random() * height).toFloat()
            )
        }
        
        // Simple force-directed algorithm (simplified Spring-Embedder)
        repeat(50) { // Iterations
            val forces = mutableMapOf<String, Pair<Float, Float>>()
            
            // Initialize forces
            elements.forEach { element ->
                forces[element.id] = Pair(0f, 0f)
            }
            
            // Repulsive forces between all nodes
            elements.forEach { element1 ->
                elements.forEach { element2 ->
                    if (element1.id != element2.id) {
                        val pos1 = positions[element1.id]!!
                        val pos2 = positions[element2.id]!!
                        
                        val dx = pos1.first - pos2.first
                        val dy = pos1.second - pos2.second
                        val distance = sqrt(dx * dx + dy * dy).coerceAtLeast(1f)
                        
                        val repulsiveForce = 10000f / (distance * distance)
                        val fx = (dx / distance) * repulsiveForce
                        val fy = (dy / distance) * repulsiveForce
                        
                        val currentForce = forces[element1.id]!!
                        forces[element1.id] = Pair(currentForce.first + fx, currentForce.second + fy)
                    }
                }
            }
            
            // Attractive forces between connected nodes
            relationships.forEach { relationship ->
                val pos1 = positions[relationship.sourceElementId]
                val pos2 = positions[relationship.targetElementId]
                
                if (pos1 != null && pos2 != null) {
                    val dx = pos2.first - pos1.first
                    val dy = pos2.second - pos1.second
                    val distance = sqrt(dx * dx + dy * dy).coerceAtLeast(1f)
                    
                    val attractiveForce = distance * 0.01f * relationship.strength
                    val fx = (dx / distance) * attractiveForce
                    val fy = (dy / distance) * attractiveForce
                    
                    val force1 = forces[relationship.sourceElementId]!!
                    val force2 = forces[relationship.targetElementId]!!
                    
                    forces[relationship.sourceElementId] = Pair(force1.first + fx, force1.second + fy)
                    forces[relationship.targetElementId] = Pair(force2.first - fx, force2.second - fy)
                }
            }
            
            // Apply forces with damping
            val damping = 0.1f
            elements.forEach { element ->
                val force = forces[element.id]!!
                val pos = positions[element.id]!!
                
                val newX = (pos.first + force.first * damping).coerceIn(50f, width - 50f)
                val newY = (pos.second + force.second * damping).coerceIn(50f, height - 50f)
                
                positions[element.id] = Pair(newX, newY)
            }
        }
        
        return elements.map { element ->
            val pos = positions[element.id]!!
            NetworkNode(
                element = element,
                x = pos.first,
                y = pos.second,
                connections = connectionCounts[element.id] ?: 0
            )
        }
    }
    
    private fun calculateHierarchicalLayout(elements: List<WorldElement>, connectionCounts: Map<String, Int>): List<NetworkNode> {
        // Sort by element type and connection count
        val groupedElements = elements.groupBy { it.type }
        val width = 1000f
        val height = 800f
        
        val nodes = mutableListOf<NetworkNode>()
        var currentY = 100f
        val levelHeight = height / groupedElements.size
        
        groupedElements.forEach { (type, elementsOfType) ->
            val sortedElements = elementsOfType.sortedByDescending { connectionCounts[it.id] ?: 0 }
            val elementsPerRow = sqrt(sortedElements.size.toDouble()).toInt().coerceAtLeast(1)
            
            sortedElements.forEachIndexed { index, element ->
                val row = index / elementsPerRow
                val col = index % elementsPerRow
                val totalCols = minOf(elementsPerRow, sortedElements.size - row * elementsPerRow)
                
                val x = width * (col + 0.5f) / totalCols
                val y = currentY + row * 80f
                
                nodes.add(
                    NetworkNode(
                        element = element,
                        x = x,
                        y = y,
                        connections = connectionCounts[element.id] ?: 0
                    )
                )
            }
            
            currentY += levelHeight
        }
        
        return nodes
    }
    
    private fun createEdges(relationships: List<Relationship>, nodes: List<NetworkNode>): List<NetworkEdge> {
        val nodeMap = nodes.associateBy { it.element.id }
        
        return relationships.mapNotNull { relationship ->
            val startNode = nodeMap[relationship.sourceElementId]
            val endNode = nodeMap[relationship.targetElementId]
            
            if (startNode != null && endNode != null) {
                NetworkEdge(
                    relationship = relationship,
                    startNode = startNode,
                    endNode = endNode
                )
            } else null
        }
    }
    
    fun selectElement(element: WorldElement?) {
        _uiState.update { 
            it.copy(
                selectedElement = element,
                nodes = it.nodes.map { node -> 
                    node.copy(isSelected = node.element.id == element?.id)
                }
            )
        }
    }
    
    fun setLayoutAlgorithm(algorithm: LayoutAlgorithm) {
        _uiState.update { it.copy(layoutAlgorithm = algorithm) }
        refreshLayout()
    }
    
    fun toggleLabels() {
        _uiState.update { it.copy(showLabels = !it.showLabels) }
    }
    
    fun filterByType(type: ElementType?) {
        _uiState.update { it.copy(selectedType = type) }
        refreshLayout()
    }
    
    private fun refreshLayout() {
        viewModelScope.launch {
            val elements = if (_uiState.value.selectedType != null) {
                _uiState.value.nodes.filter { it.element.type == _uiState.value.selectedType }.map { it.element }
            } else {
                _uiState.value.nodes.map { it.element }
            }
            
            val relationships = repository.getRelationshipsForWorld(worldId)
            val filteredRelationships = if (_uiState.value.selectedType != null) {
                val elementIds = elements.map { it.id }.toSet()
                relationships.filter { it.sourceElementId in elementIds && it.targetElementId in elementIds }
            } else {
                relationships
            }
            
            val nodes = calculateNodeLayout(elements, filteredRelationships)
            val edges = createEdges(filteredRelationships, nodes)
            
            _uiState.update { 
                it.copy(
                    nodes = nodes,
                    edges = edges
                )
            }
        }
    }
}