package com.zondo.app.di

import android.content.Context
import androidx.room.Room
import com.zondo.app.data.local.ItemDao
import com.zondo.app.data.local.ZondoDatabase
import com.zondo.app.data.remote.api.ZondoApi
import com.zondo.app.data.repository.ItemRepositoryImpl
import com.zondo.app.domain.repository.ItemRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BODY })
        .build()

    @Provides @Singleton
    fun provideRetrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl("https://jsonplaceholder.typicode.com/")
        .client(client)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    @Provides @Singleton
    fun provideZondoApi(retrofit: Retrofit): ZondoApi = retrofit.create(ZondoApi::class.java)

    @Provides @Singleton
    fun provideDatabase(@ApplicationContext ctx: Context): ZondoDatabase =
        Room.databaseBuilder(ctx, ZondoDatabase::class.java, "zondo_db").build()

    @Provides @Singleton
    fun provideItemDao(db: ZondoDatabase): ItemDao = db.itemDao()

    @Provides @Singleton
    fun provideItemRepository(api: ZondoApi, dao: ItemDao): ItemRepository =
        ItemRepositoryImpl(api, dao)
}
