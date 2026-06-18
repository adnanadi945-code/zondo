package com.zondo.app.data.remote.api

import com.zondo.app.data.remote.dto.ItemDto
import retrofit2.http.GET
import retrofit2.http.Path

interface ZondoApi {
    @GET("posts")
    suspend fun getItems(): List<ItemDto>

    @GET("posts/{id}")
    suspend fun getItemById(@Path("id") id: Int): ItemDto
}
