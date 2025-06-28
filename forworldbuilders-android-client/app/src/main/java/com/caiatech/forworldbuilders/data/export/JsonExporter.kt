package com.caiatech.forworldbuilders.data.export

import com.caiatech.forworldbuilders.data.database.entities.Relationship
import com.caiatech.forworldbuilders.data.database.entities.World
import com.caiatech.forworldbuilders.data.database.entities.WorldElement
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.*

@Serializable
data class ExportWorld(
    val id: String,
    val title: String,
    val description: String,
    val created: String,
    val lastModified: String,
    val version: Int
)

@Serializable
data class ExportElement(
    val id: String,
    val worldId: String,
    val type: String,
    val title: String,
    val content: String,
    val tags: String,
    val created: String,
    val lastModified: String,
    val version: Int
)

@Serializable
data class ExportRelationship(
    val id: String,
    val sourceElementId: String,
    val targetElementId: String,
    val type: String,
    val strength: Int,
    val description: String,
    val bidirectional: Boolean,
    val metadata: String
)

@Serializable
data class WorldExport(
    val formatVersion: String = "1.0",
    val exportedBy: String = "For World Builders Android v1.0",
    val exportDate: String,
    val world: ExportWorld,
    val elements: List<ExportElement>,
    val relationships: List<ExportRelationship>
)

@Serializable
data class AllWorldsExport(
    val formatVersion: String = "1.0",
    val exportedBy: String = "For World Builders Android v1.0",
    val exportDate: String,
    val worlds: List<WorldExport>
)

object JsonExporter {
    private val json = Json {
        prettyPrint = true
        ignoreUnknownKeys = true
    }
    
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }
    
    suspend fun exportWorld(
        world: World,
        elements: List<WorldElement>,
        relationships: List<Relationship>
    ): String = withContext(Dispatchers.IO) {
        val exportWorld = ExportWorld(
            id = world.id,
            title = world.title,
            description = world.description,
            created = dateFormat.format(world.created),
            lastModified = dateFormat.format(world.lastModified),
            version = world.version
        )
        
        val exportElements = elements.map { element ->
            ExportElement(
                id = element.id,
                worldId = element.worldId,
                type = element.type.name,
                title = element.title,
                content = element.content,
                tags = element.tags,
                created = dateFormat.format(element.created),
                lastModified = dateFormat.format(element.lastModified),
                version = element.version
            )
        }
        
        val exportRelationships = relationships.map { relationship ->
            ExportRelationship(
                id = relationship.id,
                sourceElementId = relationship.sourceElementId,
                targetElementId = relationship.targetElementId,
                type = relationship.type,
                strength = relationship.strength,
                description = relationship.description,
                bidirectional = relationship.bidirectional,
                metadata = relationship.metadata
            )
        }
        
        val worldExport = WorldExport(
            exportDate = dateFormat.format(Date()),
            world = exportWorld,
            elements = exportElements,
            relationships = exportRelationships
        )
        
        json.encodeToString(worldExport)
    }
    
    suspend fun exportAllWorlds(
        worldsData: List<Triple<World, List<WorldElement>, List<Relationship>>>
    ): String = withContext(Dispatchers.IO) {
        val worldExports = worldsData.map { (world, elements, relationships) ->
            val exportWorld = ExportWorld(
                id = world.id,
                title = world.title,
                description = world.description,
                created = dateFormat.format(world.created),
                lastModified = dateFormat.format(world.lastModified),
                version = world.version
            )
            
            val exportElements = elements.map { element ->
                ExportElement(
                    id = element.id,
                    worldId = element.worldId,
                    type = element.type.name,
                    title = element.title,
                    content = element.content,
                    tags = element.tags,
                    created = dateFormat.format(element.created),
                    lastModified = dateFormat.format(element.lastModified),
                    version = element.version
                )
            }
            
            val exportRelationships = relationships.map { relationship ->
                ExportRelationship(
                    id = relationship.id,
                    sourceElementId = relationship.sourceElementId,
                    targetElementId = relationship.targetElementId,
                    type = relationship.type,
                    strength = relationship.strength,
                    description = relationship.description,
                    bidirectional = relationship.bidirectional,
                    metadata = relationship.metadata
                )
            }
            
            WorldExport(
                exportDate = dateFormat.format(Date()),
                world = exportWorld,
                elements = exportElements,
                relationships = exportRelationships
            )
        }
        
        val allWorldsExport = AllWorldsExport(
            exportDate = dateFormat.format(Date()),
            worlds = worldExports
        )
        
        json.encodeToString(allWorldsExport)
    }
}