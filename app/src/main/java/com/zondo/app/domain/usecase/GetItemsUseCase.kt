package com.zondo.app.domain.usecase

import com.zondo.app.domain.model.Item
import com.zondo.app.domain.repository.ItemRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetItemsUseCase @Inject constructor(
    private val repository: ItemRepository
) {
    operator fun invoke(): Flow<List<Item>> = repository.getLocalItems()
    suspend fun refresh(): Result<Unit> = repository.refreshItems()
}
