package com.caiatech.forworldbuilders.data.database.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "relationships",
    foreignKeys = [
        ForeignKey(
            entity = WorldElement::class,
            parentColumns = ["id"],
            childColumns = ["sourceElementId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = WorldElement::class,
            parentColumns = ["id"],
            childColumns = ["targetElementId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["sourceElementId"]),
        Index(value = ["targetElementId"]),
        Index(value = ["sourceElementId", "targetElementId"], unique = true)
    ]
)
data class Relationship(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val sourceElementId: String,
    val targetElementId: String,
    val type: String, // e.g., "parent", "mentor", "ally", "enemy", "located_in", etc.
    val strength: Int = 5, // 1-10 scale
    val description: String = "",
    val bidirectional: Boolean = false,
    val metadata: String = "{}" // JSON string for additional data
)