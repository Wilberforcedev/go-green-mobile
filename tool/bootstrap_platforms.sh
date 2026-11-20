#!/usr/bin/env sh
# Generates the Android and iOS runner projects that are not committed.
# Existing files (including the Android manifest override) are preserved.
set -eu

flutter create --platforms=android,ios --project-name grinmates_mobile .

# Register the Supabase auth callback on iOS as well as Android.
python3 - <<'PY'
from pathlib import Path
import plistlib

plist_path = Path("ios/Runner/Info.plist")
with plist_path.open("rb") as source:
    settings = plistlib.load(source)

callback_scheme = "io.supabase.flutter"
url_types = settings.setdefault("CFBundleURLTypes", [])
if not any(
    callback_scheme in url_type.get("CFBundleURLSchemes", [])
    for url_type in url_types
):
    url_types.append({
        "CFBundleURLName": callback_scheme,
        "CFBundleURLSchemes": [callback_scheme],
    })

with plist_path.open("wb") as destination:
    plistlib.dump(settings, destination, sort_keys=False)
PY
