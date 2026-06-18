# Zondo 🚀

A production-ready Kotlin Android project with Clean Architecture.

## Tech Stack
- **Kotlin** + **Jetpack Compose** (UI)
- **Hilt** (Dependency Injection)
- **Retrofit** + **OkHttp** (Network)
- **Room** (Local Database)
- **Coroutines + Flow** (Async)
- **MVVM + Clean Architecture**

## Project Structure
```
app/src/main/java/com/zondo/app/
├── data/
│   ├── local/          # Room DB, DAO, Entities
│   ├── remote/         # Retrofit API, DTOs
│   └── repository/     # Repository Implementations
├── domain/
│   ├── model/          # Domain Models
│   ├── repository/     # Repository Interfaces
│   └── usecase/        # Use Cases
├── di/                 # Hilt Modules
└── ui/
    ├── screens/        # Composable Screens + ViewModels
    └── theme/          # Material3 Theme
```

## Setup
1. Clone the repo
2. Open in Android Studio Hedgehog or newer
3. Sync Gradle
4. Run on emulator/device (API 24+)
