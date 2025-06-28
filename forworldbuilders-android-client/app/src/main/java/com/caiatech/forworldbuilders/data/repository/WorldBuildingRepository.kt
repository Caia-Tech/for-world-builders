package com.caiatech.forworldbuilders.data.repository

import com.caiatech.forworldbuilders.data.database.dao.RelationshipDao
import com.caiatech.forworldbuilders.data.database.dao.WorldDao
import com.caiatech.forworldbuilders.data.database.dao.WorldElementDao
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.data.import.ImportedData
import kotlinx.coroutines.flow.Flow
import java.util.Date
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WorldBuildingRepository @Inject constructor(
    private val worldDao: WorldDao,
    private val worldElementDao: WorldElementDao,
    private val relationshipDao: RelationshipDao
) {
    // World operations
    fun getAllWorlds(): Flow<List<World>> = worldDao.getAllWorlds()
    
    suspend fun getWorldById(worldId: String): World? = worldDao.getWorldById(worldId)
    
    suspend fun getWorldCount(): Int = worldDao.getWorldCount()
    
    suspend fun canCreateNewWorld(): Boolean {
        // Free version limit: 3 worlds
        return getWorldCount() < 3
    }
    
    suspend fun createWorld(title: String, description: String): Result<World> {
        return if (canCreateNewWorld()) {
            val world = World(
                title = title,
                description = description
            )
            worldDao.insertWorld(world)
            Result.success(world)
        } else {
            Result.failure(Exception("World limit reached. Upgrade to Pro for unlimited worlds."))
        }
    }
    
    suspend fun updateWorld(world: World) {
        worldDao.updateWorld(world.copy(lastModified = Date()))
    }
    
    suspend fun deleteWorld(world: World) {
        worldDao.deleteWorld(world)
    }
    
    // World Element operations
    fun getElementsForWorld(worldId: String): Flow<List<WorldElement>> = 
        worldElementDao.getElementsForWorld(worldId)
    
    fun getElementsByType(worldId: String, type: ElementType): Flow<List<WorldElement>> =
        worldElementDao.getElementsByType(worldId, type)
    
    suspend fun getElementById(elementId: String): WorldElement? = 
        worldElementDao.getElementById(elementId)
    
    suspend fun getElementCountForWorld(worldId: String): Int = 
        worldElementDao.getElementCountForWorld(worldId)
    
    suspend fun canCreateNewElement(worldId: String): Boolean {
        // Free version limit: 100 elements per world
        return getElementCountForWorld(worldId) < 100
    }
    
    suspend fun createElement(
        worldId: String,
        type: ElementType,
        title: String,
        content: String,
        tags: String = ""
    ): Result<WorldElement> {
        return if (canCreateNewElement(worldId)) {
            val element = WorldElement(
                worldId = worldId,
                type = type,
                title = title,
                content = content,
                tags = tags
            )
            worldElementDao.insertElement(element)
            Result.success(element)
        } else {
            Result.failure(Exception("Element limit reached for this world. Upgrade to Pro for unlimited elements."))
        }
    }
    
    suspend fun updateElement(element: WorldElement) {
        worldElementDao.updateElement(element.copy(lastModified = Date()))
    }
    
    suspend fun deleteElement(element: WorldElement) {
        // Delete relationships first
        relationshipDao.deleteRelationshipsForElement(element.id)
        worldElementDao.deleteElement(element)
    }
    
    fun searchElements(worldId: String, query: String): Flow<List<WorldElement>> =
        worldElementDao.searchElements(worldId, query)
    
    // Relationship operations
    fun getRelationshipsForElement(elementId: String): Flow<List<Relationship>> =
        relationshipDao.getRelationshipsForElement(elementId)
    
    suspend fun createRelationship(
        sourceElementId: String,
        targetElementId: String,
        type: String,
        strength: Int = 5,
        description: String = "",
        bidirectional: Boolean = false
    ): Relationship {
        val relationship = Relationship(
            sourceElementId = sourceElementId,
            targetElementId = targetElementId,
            type = type,
            strength = strength,
            description = description,
            bidirectional = bidirectional
        )
        relationshipDao.insertRelationship(relationship)
        return relationship
    }
    
    suspend fun updateRelationship(relationship: Relationship) {
        relationshipDao.updateRelationship(relationship)
    }
    
    suspend fun deleteRelationship(relationship: Relationship) {
        relationshipDao.deleteRelationship(relationship)
    }
    
    suspend fun getRelationshipsForWorld(worldId: String): List<Relationship> =
        relationshipDao.getRelationshipsForWorld(worldId)
    
    suspend fun getElementsForWorldList(worldId: String): List<WorldElement> =
        worldElementDao.getElementsForWorldList(worldId)
    
    // Import operations
    suspend fun checkForConflicts(importData: ImportedData): List<String> {
        val conflictingWorlds = mutableListOf<String>()
        
        importData.worlds.forEach { world ->
            val existing = worldDao.getWorldById(world.id)
            if (existing != null) {
                conflictingWorlds.add(world.title)
            }
        }
        
        return conflictingWorlds
    }
    
    suspend fun importData(
        importData: ImportedData,
        overwriteExisting: Boolean = false
    ): Result<Triple<Int, Int, Int>> {
        return try {
            var importedWorlds = 0
            var importedElements = 0
            var importedRelationships = 0
            
            // Import worlds
            importData.worlds.forEach { world ->
                val existing = worldDao.getWorldById(world.id)
                if (existing == null || overwriteExisting) {
                    if (existing != null && overwriteExisting) {
                        // Delete existing world and all its data
                        deleteWorld(existing)
                    }
                    worldDao.insertWorld(world)
                    importedWorlds++
                }
            }
            
            // Import elements
            importData.elements.forEach { element ->
                val existing = worldElementDao.getElementById(element.id)
                if (existing == null || overwriteExisting) {
                    if (existing != null && overwriteExisting) {
                        worldElementDao.deleteElement(existing)
                    }
                    worldElementDao.insertElement(element)
                    importedElements++
                }
            }
            
            // Import relationships
            importData.relationships.forEach { relationship ->
                val existing = relationshipDao.getRelationshipBetween(
                    relationship.sourceElementId,
                    relationship.targetElementId
                )
                if (existing == null || overwriteExisting) {
                    if (existing != null && overwriteExisting) {
                        relationshipDao.deleteRelationship(existing)
                    }
                    relationshipDao.insertRelationship(relationship)
                    importedRelationships++
                }
            }
            
            Result.success(Triple(importedWorlds, importedElements, importedRelationships))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}