package com.zondo.app.domain.repository

import com.zondo.app.domain.model.Item
import kotlinx.coroutines.flow.Flow

interface ItemRepository {
    fun getLocalItems(): Flow<List<Item>>
    suspend fun refreshItems(): Result<Unit>
}
