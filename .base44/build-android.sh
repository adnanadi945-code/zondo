#!/usr/bin/env bash
#
# Builds the Zondo Android debug APK from the cloned source and publishes a
# status page + downloadable APK for the Base44 sandbox preview.
#
# Zondo is an Android app, so there is no web server to run: this script is what
# "running the project" means in the sandbox. It installs the Android SDK into a
# volume (never into the repo), builds the APK, and writes /dist so the `preview`
# nginx service can show the result on host port 3000.
#
# Always exits 0 after publishing, so the preview comes up even when the build
# fails and shows the failure (and its log) instead of a blank page.
set -uo pipefail

SDK_DIR="${ANDROID_HOME:-/opt/android-sdk}"
DIST_DIR="${DIST_DIR:-/dist}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
LOG_FILE="$DIST_DIR/build.log"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
SDK_PACKAGES=("platform-tools" "platforms;android-34" "build-tools;34.0.0")

STARTED_AT="$(date -Is)"
BUILD_STATUS="FAILED"
APK_SOURCE="$WORKSPACE_DIR/app/build/outputs/apk/debug/app-debug.apk"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/app-debug.apk"
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Zondo Android build started $STARTED_AT ==="

publish_page() {
  local apk_info=""
  if [ -f "$DIST_DIR/app-debug.apk" ]; then
    apk_info="<p><a class=\"button\" href=\"/app-debug.apk\">Download app-debug.apk ($(du -h "$DIST_DIR/app-debug.apk" | cut -f1))</a></p>"
  fi

  local status_class="ok"
  [ "$BUILD_STATUS" = "FAILED" ] && status_class="bad"

  {
    cat <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Zondo &mdash; Android build</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; padding: 2.5rem 1.5rem; background: #14121a; color: #e8e6ef;
         font: 16px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 760px; margin: 0 auto; }
  h1 { margin: 0 0 .25rem; font-size: 1.6rem; letter-spacing: -.01em; }
  .sub { color: #a29fb2; margin: 0 0 1.75rem; }
  .status { display: inline-block; padding: .2rem .7rem; border-radius: 999px;
            font-size: .8rem; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; }
  .ok { background: #1f4232; color: #7ee2a8; }
  .bad { background: #46202a; color: #ff9db1; }
  .card { background: #1d1a26; border: 1px solid #2c2838; border-radius: 14px;
          padding: 1.25rem 1.35rem; margin-bottom: 1rem; }
  .card h2 { margin: 0 0 .6rem; font-size: 1rem; color: #cfcbe0; }
  .button { display: inline-block; background: #6750a4; color: #fff; text-decoration: none;
            padding: .6rem 1rem; border-radius: 10px; font-weight: 600; }
  pre { margin: 0; max-height: 22rem; overflow: auto; background: #100e15; border-radius: 10px;
        padding: .9rem; font-size: .78rem; line-height: 1.45; white-space: pre-wrap; }
  code { background: #100e15; padding: .1rem .35rem; border-radius: 5px; font-size: .85em; }
  ul { margin: .4rem 0 0; padding-left: 1.2rem; color: #c9c5d8; }
  li { margin: .25rem 0; }
</style>
</head>
<body>
<main>
  <h1>Zondo</h1>
  <p class="sub">Kotlin &middot; Jetpack Compose &middot; Clean Architecture &mdash; Android app</p>

  <div class="card">
    <p><span class="status $status_class">$BUILD_STATUS</span></p>
    <p><strong>Debug APK built from this branch's source.</strong></p>
    $apk_info
  </div>

  <div class="card">
    <h2>Why you don't see the app here</h2>
    <p>Zondo is a native Android app. A browser preview can't run an APK, and this
       sandbox has no hardware virtualization (<code>/dev/kvm</code>), so an Android
       emulator can't run here either. What this page can do is build the real app
       and hand you the result.</p>
    <h2 style="margin-top:1rem">How to see it running</h2>
    <ul>
      <li>Install <code>app-debug.apk</code> on an Android device or emulator (API 24+).</li>
      <li>Or open the repo in Android Studio and run it there.</li>
    </ul>
    <p style="color:#a29fb2;margin:.9rem 0 0">The app loads posts from
       <code>https://jsonplaceholder.typicode.com/</code> (a public API, no key needed)
       and caches them in Room.</p>
  </div>

  <div class="card">
    <h2>Build log</h2>
    <pre>
HTML
    sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$LOG_FILE" | tail -n 120
    cat <<HTML
</pre>
  </div>
</main>
</body>
</html>
HTML
  } > "$DIST_DIR/index.html"

  printf '{"status":"%s","startedAt":"%s","finishedAt":"%s"}\n' \
    "$BUILD_STATUS" "$STARTED_AT" "$(date -Is)" > "$DIST_DIR/build-status.json"
}

finish() {
  cp -f "$LOG_FILE" "$DIST_DIR/build.log" 2>/dev/null || true
  publish_page
  echo "=== Publish complete (status: $BUILD_STATUS) ==="
  exit 0
}
trap finish EXIT

# --- host tooling the gradle image doesn't ship -----------------------------
if ! command -v unzip >/dev/null 2>&1; then
  echo "--- installing unzip"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends unzip ca-certificates
fi

# --- Android SDK (persisted in the android-sdk volume) ----------------------
SDKMANAGER="$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"

if [ ! -x "$SDKMANAGER" ]; then
  echo "--- installing Android command line tools"
  tmp_dir="$(mktemp -d)"
  curl -sSLo "$tmp_dir/cmdline-tools.zip" "$CMDLINE_TOOLS_URL"
  unzip -q "$tmp_dir/cmdline-tools.zip" -d "$tmp_dir"
  mkdir -p "$SDK_DIR/cmdline-tools"
  rm -rf "$SDK_DIR/cmdline-tools/latest"
  mv "$tmp_dir/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"
  rm -rf "$tmp_dir"
fi

export PATH="$SDK_DIR/platform-tools:$SDK_DIR/cmdline-tools/latest/bin:$PATH"

echo "--- accepting SDK licenses"
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

echo "--- installing SDK packages: ${SDK_PACKAGES[*]}"
if ! "$SDKMANAGER" --install "${SDK_PACKAGES[@]}" >/dev/null; then
  echo "!!! SDK package installation failed"
  exit 1
fi

# --- build ------------------------------------------------------------------
cd "$WORKSPACE_DIR"

if [ ! -x ./gradlew ]; then
  echo "--- gradle wrapper missing, generating it"
  gradle wrapper --gradle-version 8.4 --distribution-type bin >/dev/null || exit 1
fi

echo "--- assembling debug APK (gradlew assembleDebug)"
./gradlew --no-daemon assembleDebug
gradle_exit=$?
cp -f "$LOG_FILE" "$DIST_DIR/build.log" 2>/dev/null || true

if [ "$gradle_exit" -eq 0 ] && [ -f "$APK_SOURCE" ]; then
  cp -f "$APK_SOURCE" "$DIST_DIR/app-debug.apk"
  BUILD_STATUS="SUCCESS"
  echo "--- APK ready: app-debug.apk ($(du -h "$DIST_DIR/app-debug.apk" | cut -f1))"
else
  BUILD_STATUS="FAILED"
  echo "!!! Build failed with exit code $gradle_exit"
fi
