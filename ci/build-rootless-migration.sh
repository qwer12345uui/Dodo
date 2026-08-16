#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
DEPS_DIR="${RUNNER_TEMP:-/tmp}/dodo-rootless-deps"
THEOS="${THEOS:-$ROOT_DIR/theos}"
export THEOS
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

rm -rf "$DEPS_DIR"
mkdir -p "$DEPS_DIR" "$THEOS/lib/iphone/rootless" "$ROOT_DIR/logs"

build_dependency() {
    local name="$1"
    local source="$2"
    local ref="$3"
    local dir="$DEPS_DIR/$name"

    echo "== Fetch $name ($ref) =="
    git clone --depth 1 --branch "$ref" "$source" "$dir"
    echo "== Build $name rootless =="
    make -C "$dir" clean || true
    make -C "$dir" package ROOTLESS=1 ROOTHIDE=0 THEOS_PACKAGE_SCHEME=rootless TARGET=iphone:clang:latest:15.0 FINALPACKAGE=1 -j"$NCPU"

    local framework
    framework="$(find "$dir" -type d -name "$name.framework" ! -path '*dSYM*' | head -n 1 || true)"
    if [[ -z "$framework" ]]; then
        echo "ERROR: $name.framework was not produced" >&2
        exit 1
    fi
    rm -rf "$THEOS/lib/$name.framework" "$THEOS/lib/iphone/rootless/$name.framework"
    cp -R "$framework" "$THEOS/lib/$name.framework"
    cp -R "$framework" "$THEOS/lib/iphone/rootless/$name.framework"
}

build_dependency GSCore https://github.com/qwer12345uui/GSCore.git migration/ios15-rootless-roothide
build_dependency Comet https://github.com/qwer12345uui/Comet.git migration/ios15-rootless-roothide
# GSWeather source is not supplied in this migration. Build it only as an external
# dependency candidate; its DEB and every Mach-O remain subject to the same audit.
build_dependency GSWeather https://github.com/ginsudev/GSWeather.git main

ORION_STUB="$THEOS/vendor/lib/Orion.framework"
if [[ ! -d "$ORION_STUB" ]]; then
    echo "ERROR: Rootless Orion link stub is unavailable in Theos" >&2
    exit 1
fi
rm -rf "$THEOS/lib/Orion.framework" "$THEOS/lib/iphone/rootless/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/iphone/rootless/Orion.framework"

echo "== Build Dodo rootless package =="
cd "$ROOT_DIR"
rm -rf .theos packages
make package ROOTLESS=1 ROOTHIDE=0 THEOS_PACKAGE_SCHEME=rootless TARGET=iphone:clang:latest:15.0 FINALPACKAGE=1 -j"$NCPU"

mkdir -p "$ROOT_DIR/candidates"
find "$ROOT_DIR/packages" "$DEPS_DIR" -type f -name '*.deb' -print0 | while IFS= read -r -d '' deb; do
    cp "$deb" "$ROOT_DIR/candidates/"
done
ls -lah "$ROOT_DIR/candidates"
