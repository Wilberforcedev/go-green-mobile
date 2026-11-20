#!/usr/bin/env sh
# Generates the Android and iOS runner projects that are not committed.
# Existing files (including the Android manifest override) are preserved.
set -eu

flutter create --platforms=android,ios --project-name grinmates_mobile .
