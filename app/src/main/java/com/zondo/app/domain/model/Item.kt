package com.zondo.app.domain.model

data class Item(
    val id: Int,
    val title: String,
    val description: String,
    val imageUrl: String? = null
)
