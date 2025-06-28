package com.caiatech.forworldbuilders.data.import

import com.caiatech.forworldbuilders.data.database.entities.ElementType
import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import com.caiatech.forworldbuilders.data.export.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.*

sealed class ImportResult {
    data class Success(val importedWorlds: Int, val importedElements: Int, val importedRelationships: Int) : ImportResult()
    data class Error(val message: String) : ImportResult()
    data class Conflict(val conflictingWorlds: List<String>) : ImportResult()
}

data class ImportedData(
    val worlds: List<World>,
    val elements: List<WorldElement>,
    val relationships: List<Relationship>
)

object JsonImporter {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }
    
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }
    
    suspend fun parseImportData(jsonContent: String): Result<ImportedData> = withContext(Dispatchers.IO) {
        try {
            // Try to parse as AllWorldsExport first
            val importData = try {
                val allWorldsExport = json.decodeFromString<AllWorldsExport>(jsonContent)
                convertAllWorldsExport(allWorldsExport)
            } catch (e: Exception) {
                // Try to parse as single WorldExport
                try {
                    val worldExport = json.decodeFromString<WorldExport>(jsonContent)
                    convertWorldExport(worldExport)
                } catch (e2: Exception) {
                    return@withContext Result.failure(Exception("Invalid JSON format. Expected ForWorldBuilders export format."))
                }
            }
            
            Result.success(importData)
        } catch (e: Exception) {
            Result.failure(Exception("Failed to parse JSON: ${e.message}"))
        }
    }
    
    private fun convertAllWorldsExport(allWorldsExport: AllWorldsExport): ImportedData {
        val worlds = mutableListOf<World>()
        val elements = mutableListOf<WorldElement>()
        val relationships = mutableListOf<Relationship>()
        
        allWorldsExport.worlds.forEach { worldExport ->
            val convertedData = convertWorldExport(worldExport)
            worlds.addAll(convertedData.worlds)
            elements.addAll(convertedData.elements)
            relationships.addAll(convertedData.relationships)
        }
        
        return ImportedData(worlds, elements, relationships)
    }
    
    private fun convertWorldExport(worldExport: WorldExport): ImportedData {
        val world = convertExportWorld(worldExport.world)
        val elements = worldExport.elements.map { convertExportElement(it) }
        val relationships = worldExport.relationships.map { convertExportRelationship(it) }
        
        return ImportedData(listOf(world), elements, relationships)
    }
    
    private fun convertExportWorld(exportWorld: ExportWorld): World {
        return World(
            id = exportWorld.id,
            title = exportWorld.title,
            description = exportWorld.description,
            created = parseDate(exportWorld.created) ?: Date(),
            lastModified = parseDate(exportWorld.lastModified) ?: Date(),
            version = exportWorld.version
        )
    }
    
    private fun convertExportElement(exportElement: ExportElement): WorldElement {
        val elementType = try {
            ElementType.valueOf(exportElement.type)
        } catch (e: IllegalArgumentException) {
            ElementType.CUSTOM
        }
        
        return WorldElement(
            id = exportElement.id,
            worldId = exportElement.worldId,
            type = elementType,
            title = exportElement.title,
            content = exportElement.content,
            tags = exportElement.tags,
            created = parseDate(exportElement.created) ?: Date(),
            lastModified = parseDate(exportElement.lastModified) ?: Date(),
            version = exportElement.version
        )
    }
    
    private fun convertExportRelationship(exportRelationship: ExportRelationship): Relationship {
        return Relationship(
            id = exportRelationship.id,
            sourceElementId = exportRelationship.sourceElementId,
            targetElementId = exportRelationship.targetElementId,
            type = exportRelationship.type,
            strength = exportRelationship.strength,
            description = exportRelationship.description,
            bidirectional = exportRelationship.bidirectional,
            metadata = exportRelationship.metadata
        )
    }
    
    private fun parseDate(dateString: String): Date? {
        return try {
            dateFormat.parse(dateString)
        } catch (e: Exception) {
            null
        }
    }
    
    fun validateImportData(importData: ImportedData): List<String> {
        val errors = mutableListOf<String>()
        
        // Check for empty data
        if (importData.worlds.isEmpty()) {
            errors.add("No worlds found in import data")
        }
        
        // Validate world IDs and titles
        importData.worlds.forEach { world ->
            if (world.id.isBlank()) {
                errors.add("World has empty ID")
            }
            if (world.title.isBlank()) {
                errors.add("World '${world.id}' has empty title")
            }
        }
        
        // Validate elements reference valid worlds
        val worldIds = importData.worlds.map { it.id }.toSet()
        importData.elements.forEach { element ->
            if (element.worldId !in worldIds) {
                errors.add("Element '${element.title}' references unknown world '${element.worldId}'")
            }
            if (element.title.isBlank()) {
                errors.add("Element '${element.id}' has empty title")
            }
        }
        
        // Validate relationships reference valid elements
        val elementIds = importData.elements.map { it.id }.toSet()
        importData.relationships.forEach { relationship ->
            if (relationship.sourceElementId !in elementIds) {
                errors.add("Relationship references unknown source element '${relationship.sourceElementId}'")
            }
            if (relationship.targetElementId !in elementIds) {
                errors.add("Relationship references unknown target element '${relationship.targetElementId}'")
            }
        }
        
        return errors
    }
}