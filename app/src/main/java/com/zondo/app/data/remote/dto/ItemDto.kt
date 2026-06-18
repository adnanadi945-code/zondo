package com.zondo.app.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.zondo.app.domain.model.Item

data class ItemDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String,
    @SerializedName("body") val description: String
) {
    fun toItem() = Item(id = id, title = title, description = description)
}
