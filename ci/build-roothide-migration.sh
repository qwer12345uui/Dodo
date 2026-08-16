#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
DEPS_DIR="${RUNNER_TEMP:-/tmp}/dodo-roothide-migration-deps"
THEOS="${THEOS:-$ROOT_DIR/theos}"
export THEOS
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

rm -rf "$DEPS_DIR"
mkdir -p "$DEPS_DIR" "$THEOS/lib/iphone/roothide" "$ROOT_DIR/logs"

build_dependency() {
    local name="$1"
    local source="$2"
    local ref="$3"
    local dir="$DEPS_DIR/$name"

    echo "== Fetch $name ($ref) =="
    git clone --depth 1 --branch "$ref" "$source" "$dir"
    echo "== Build $name RootHide =="
    make -C "$dir" clean || true
    make -C "$dir" package ROOTHIDE=1 ROOTLESS=0 THEOS_PACKAGE_SCHEME=roothide TARGET=iphone:clang:latest:15.0 FINALPACKAGE=1 -j"$NCPU"

    local framework
    framework="$(find "$dir" -type d -name "$name.framework" ! -path '*dSYM*' | head -n 1 || true)"
    if [[ -z "$framework" ]]; then
        echo "ERROR: $name.framework was not produced" >&2
        exit 1
    fi
    rm -rf "$THEOS/lib/$name.framework" "$THEOS/lib/iphone/roothide/$name.framework"
    cp -R "$framework" "$THEOS/lib/$name.framework"
    cp -R "$framework" "$THEOS/lib/iphone/roothide/$name.framework"
}

build_dependency GSCore https://github.com/qwer12345uui/GSCore.git migration/ios15-rootless-roothide
build_dependency Comet https://github.com/qwer12345uui/Comet.git migration/ios15-rootless-roothide
# GSWeather source is external to this migration. Its RootHide compatibility is
# intentionally not patched here; package and Mach-O audits must reject it if it
# contains incompatible fixed bootstrap or library paths.
build_dependency GSWeather https://github.com/ginsudev/GSWeather.git main

ORION_STUB="$THEOS/vendor/lib/Orion.framework"
if [[ ! -d "$ORION_STUB" ]]; then
    echo "ERROR: RootHide Orion link stub is unavailable in Theos" >&2
    exit 1
fi
rm -rf "$THEOS/lib/Orion.framework" "$THEOS/lib/iphone/roothide/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/iphone/roothide/Orion.framework"

echo "== Build Dodo RootHide package =="
cd "$ROOT_DIR"
rm -rf .theos packages
make package ROOTHIDE=1 ROOTLESS=0 THEOS_PACKAGE_SCHEME=roothide TARGET=iphone:clang:latest:15.0 FINALPACKAGE=1 -j"$NCPU"

mkdir -p "$ROOT_DIR/candidates"
find "$ROOT_DIR/packages" "$DEPS_DIR" -type f -name '*.deb' -print0 | while IFS= read -r -d '' deb; do
    cp "$deb" "$ROOT_DIR/candidates/"
done
ls -lah "$ROOT_DIR/candidates"
