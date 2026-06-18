package com.zondo.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [ItemEntity::class], version = 1, exportSchema = false)
abstract class ZondoDatabase : RoomDatabase() {
    abstract fun itemDao(): ItemDao
}
