# Zondo — working notes

Zondo is a **native Android app** (Kotlin + Jetpack Compose, Clean Architecture).
There is no web server in this repository: don't look for one.

## How this project runs in the Base44 sandbox

A browser preview cannot execute an APK, and this sandbox has **no `/dev/kvm`**
(no `vmx`/`svm` CPU flags), so an Android emulator cannot run here either.
What `docker-compose.base44.yml` does instead is build the real debug APK from
the cloned source and serve it, with the build log, on host port 3000:

- `android-build` — one-shot (`gradle:8.4-jdk17`). Installs the Android SDK into
  the `android-sdk` volume on first run, builds the APK, publishes the status
  page + APK into the `dist` volume. It **always exits 0**, even when the build
  fails, so the preview still starts and reports the failure on the page.
- `preview` — `nginx:alpine` on host port 3000, serving that `dist` volume
  read-only.

Volumes: `android-sdk` (SDK, ~1.5 GB), `gradle-home` (Gradle dist + caches),
`dist` (published page/APK/log). Nothing is written into the repo except
`app/build/`, which is git-ignored.

### Rebuilding after a code change

```bash
docker compose -f docker-compose.base44.yml run --rm android-build
```

Then reload the preview. The first build takes ~10 minutes (SDK + Gradle
distribution + dependency downloads); later builds are incremental and take
well under a minute. `up -d` alone does **not** rebuild — it only re-runs the
build service when the container is recreated (compose config change).

### Verifying the app is built

```bash
curl -sf http://localhost:3000/build-status.json     # {"status":"SUCCESS",...}
curl -sfI http://localhost:3000/app-debug.apk        # 200, ~13 MB
```

The full log of the last build is in the `dist` volume (`/dist/build.log`).
`aapt2`/`sdkmanager` live in the `android-sdk` volume (e.g. mount both volumes
into a `gradle:8.4-jdk17` container to inspect the APK).

## Repo gaps that were repaired to make it build

Non-obvious — the project did not build from a clean clone before these:

1. **`gradle.properties` was missing.** AGP fails `:app:checkDebugAarMetadata`
   with "contains AndroidX dependencies, but the `android.useAndroidX` property
   is not enabled" without `android.useAndroidX=true`.
2. **The Gradle wrapper was missing** (`gradlew`, `gradlew.bat`,
   `gradle/wrapper/gradle-wrapper.jar`); only `gradle-wrapper.properties`
   existed. Generated for Gradle 8.4 to match the properties file.
3. **Launcher icon resources were missing.** `AndroidManifest.xml` references
   `@mipmap/ic_launcher` and `@mipmap/ic_launcher_round`, but no `mipmap`
   resources existed, which fails the resource link step. Added adaptive icons
   (`mipmap-anydpi-v26/*.xml` + `drawable/ic_launcher_foreground.xml` +
   `values/colors.xml`) and PNG fallbacks for API 24–25 in mdpi…xxxhdpi.

## Credentials

None required. The only remote service the app talks to is the public
`https://jsonplaceholder.typicode.com/` API (see `di/AppModule.kt`), cached
locally with Room. There is no `.env` / secrets wiring.

## Tests

No test sources exist yet (`testImplementation(junit)` is declared but
`app/src/test` is absent), and `.github/workflows/blank.yml` is a placeholder
that only echoes text. `./gradlew test` currently runs nothing.

## Sandbox overrides

None. There is no dev server, so no host/origin allowlist or
`BASE44_PREVIEW_MODE` gating was needed; application code is unchanged.
