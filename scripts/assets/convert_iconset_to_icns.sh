#!/usr/bin/env bash

set -exu

# xcode or iconutil re-encode PNGs, increasing the final .icns file for no reason; use the local helper instead
scripts/assets/createicns resources/icons/app/app.iconset
mv app.icns resources/icons/app/app.icns
