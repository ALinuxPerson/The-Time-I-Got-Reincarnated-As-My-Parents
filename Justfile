set dotenv-load := true

macos_bundle := "com.example.theTimeIGotReincarnatedAsMyParents"
android_app_id := "com.example.the_time_i_got_reincarnated_as_my_parents"
db_name := "reincarnated_as_parents.db"

# Default: run on macOS desktop
default: desktop

# Run the game on macOS desktop
desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${GEMINI_API_KEY:-}" ]; then
      flutter run -d macos --dart-define="GEMINI_API_KEY=${GEMINI_API_KEY}"
    else
      flutter run -d macos
    fi

# Deploy and run on the attached mobile device (Android or iOS)
mobile:
    #!/usr/bin/env bash
    set -euo pipefail
    device_id=$(flutter devices --machine | python3 -c "
    import json, sys
    devices = json.load(sys.stdin)
    for d in devices:
        tp = d.get('targetPlatform', '')
        if tp.startswith('android') or tp.startswith('ios'):
            print(d['id'])
            break
    ")
    if [ -z "$device_id" ]; then
      echo "No attached Android or iOS device found. Connect a device and run 'flutter devices'."
      exit 1
    fi
    echo "Deploying to mobile device: $device_id"
    if [ -n "${GEMINI_API_KEY:-}" ]; then
      flutter run -d "$device_id" --dart-define="GEMINI_API_KEY=${GEMINI_API_KEY}"
    else
      flutter run -d "$device_id"
    fi

# Reset all saved game data (SQLite DB on macOS desktop + attached Android device)
reset:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Resetting local macOS desktop save data..."
    if [ -d "$HOME/Library/Containers/{{macos_bundle}}" ]; then
      find "$HOME/Library/Containers/{{macos_bundle}}" -name "{{db_name}}*" -delete 2>/dev/null || true
    fi
    if [ -d "$HOME/Library/Application Support/{{macos_bundle}}" ]; then
      find "$HOME/Library/Application Support/{{macos_bundle}}" -name "{{db_name}}*" -delete 2>/dev/null || true
    fi
    if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
      echo "Resetting attached Android device save data..."
      adb shell pm clear {{android_app_id}} >/dev/null 2>&1 || true
    fi
    echo "All game data has been reset."
