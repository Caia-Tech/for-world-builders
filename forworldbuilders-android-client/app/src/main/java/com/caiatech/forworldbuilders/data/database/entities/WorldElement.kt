package com.caiatech.forworldbuilders.data.database.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

enum class ElementType {
    CHARACTER,
    LOCATION,
    EVENT,
    CULTURE,
    LANGUAGE,
    TIMELINE,
    PLOT,
    ORGANIZATION,
    ITEM,
    CONCEPT,
    CUSTOM
}

@Entity(
    tableName = "world_elements",
    foreignKeys = [
        ForeignKey(
            entity = World::class,
            parentColumns = ["id"],
            childColumns = ["worldId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["worldId"]),
        Index(value = ["worldId", "type"])
    ]
)
data class WorldElement(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val worldId: String,
    val type: ElementType,
    val title: String,
    val content: String, // JSON string containing element-specific data
    val tags: String = "", // Comma-separated tags
    val created: Date = Date(),
    val lastModified: Date = Date(),
    val version: Int = 1
)