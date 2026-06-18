package com.zondo.app.data.repository

import com.zondo.app.data.local.ItemDao
import com.zondo.app.data.local.ItemEntity
import com.zondo.app.data.remote.api.ZondoApi
import com.zondo.app.domain.model.Item
import com.zondo.app.domain.repository.ItemRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class ItemRepositoryImpl @Inject constructor(
    private val api: ZondoApi,
    private val dao: ItemDao
) : ItemRepository {

    override fun getLocalItems(): Flow<List<Item>> {
        return dao.getAllItems().map { list ->
            list.map { Item(it.id, it.title, it.description) }
        }
    }

    override suspend fun refreshItems(): Result<Unit> {
        return try {
            val remote = api.getItems()
            dao.clearAll()
            dao.insertItems(remote.map { ItemEntity(it.id, it.title, it.description) })
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
