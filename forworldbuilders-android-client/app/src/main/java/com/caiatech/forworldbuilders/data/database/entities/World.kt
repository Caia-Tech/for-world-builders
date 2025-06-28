package com.caiatech.forworldbuilders.data.database.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(tableName = "worlds")
data class World(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val description: String,
    val created: Date = Date(),
    val lastModified: Date = Date(),
    val version: Int = 1
)