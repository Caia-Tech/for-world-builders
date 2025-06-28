package com.caiatech.forworldbuilders.data.database

import androidx.room.TypeConverter
import com.caiatech.forworldbuilders.data.database.entities.ElementType
import java.util.Date

class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun fromElementType(value: ElementType): String {
        return value.name
    }

    @TypeConverter
    fun toElementType(value: String): ElementType {
        return ElementType.valueOf(value)
    }
}