#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
THEOS="${THEOS:-$ROOT_DIR/theos}"
DEPS_DIR="${RUNNER_TEMP:-/tmp}/dodo-v5-deps"
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
export THEOS

rm -rf "$DEPS_DIR" "$ROOT_DIR/.theos" "$ROOT_DIR/packages" "$ROOT_DIR/candidates"
mkdir -p "$DEPS_DIR" "$THEOS/lib/iphone/rootless" "$THEOS/sdks" "$ROOT_DIR/candidates"

# Apple's public SDK omits SpringBoard and the other private frameworks used by
# Dodo. Use the iOS 15.6 Theos SDK, which provides link-only private stubs.
SDK_REPO="$DEPS_DIR/theos-sdks"
git clone --depth 1 --filter=blob:none --sparse https://github.com/theos/sdks.git "$SDK_REPO"
git -C "$SDK_REPO" sparse-checkout set iPhoneOS15.6.sdk
rm -rf "$THEOS/sdks/iPhoneOS15.6.sdk"
cp -R "$SDK_REPO/iPhoneOS15.6.sdk" "$THEOS/sdks/iPhoneOS15.6.sdk"
test -d "$THEOS/sdks/iPhoneOS15.6.sdk/System/Library/PrivateFrameworks/SpringBoard.framework"

build_dependency() {
    local name="$1"
    local source="$2"
    local ref="$3"
    local directory="$DEPS_DIR/$name"

    echo "== Fetch $name ($ref) =="
    git clone --depth 1 --branch "$ref" "$source" "$directory"

    # Current GSCore migration sources retain one iOS 16-only URL initializer.
    # Patch it in the CI checkout so the framework remains deployable on iOS 15.
    if [[ "$name" == "GSCore" ]]; then
        perl -0pi -e 's/\.init\(filePath: tweak\.prefsPath\)/.init(fileURLWithPath: tweak.prefsPath)/g' \
            "$directory/Sources/GSCore/Core/Ecosystem/Tweaks/TweakDescriptor.swift"
        perl -0pi -e 's/import Foundation\n/import Foundation\nimport CoreGraphics\n/' \
            "$directory/Sources/GSCore/Core/Ecosystem/Tweaks/Tweak+Preferences.swift"
    fi

    echo "== Build $name framework for rootless =="
    make -C "$directory" clean || true
    # Dodo only needs each framework at link time. Building a dependency package
    # can fail in an unrelated staging hook even after its framework archive was
    # produced, so build the framework target directly and copy that output.
    make -C "$directory" \
        ROOTLESS=1 ROOTHIDE=0 THEOS_PACKAGE_SCHEME=rootless \
        TARGET=iphone:clang:15.6:15.0 ARCHS=arm64e -j"$NCPU"

    local framework
    framework="$(find "$directory" -type d -name "$name.framework" ! -path '*dSYM*' | head -n 1 || true)"
    if [[ -z "$framework" ]]; then
        echo "ERROR: $name.framework was not produced" >&2
        exit 1
    fi

    # Framework makefiles assemble their architecture-specific Swift module
    # directory during staging. We only build the framework target above, so
    # mirror that small staging step before compiling Dodo against it.
    local swiftmodule
    swiftmodule="$(find "$directory/.theos/obj" -path '*arm64e*' -name "$name.swiftmodule" -type f | head -n 1 || true)"
    if [[ -n "$swiftmodule" ]]; then
        mkdir -p "$framework/Modules/$name.swiftmodule"
        cp "$swiftmodule" "$framework/Modules/$name.swiftmodule/arm64e-apple-ios.swiftmodule"
    fi

    # Preserve the C submodule headers and module map imported by the framework's
    # Swift module (for example GSCore imports GSCoreC).
    mkdir -p "$framework/Headers"
    while IFS= read -r header; do
        cp "$header" "$framework/Headers/"
    done < <(find "$directory/Sources" -type f -path '*C/include/*' -print)

    rm -rf "$THEOS/lib/$name.framework" "$THEOS/lib/iphone/rootless/$name.framework"
    cp -R "$framework" "$THEOS/lib/$name.framework"
    cp -R "$framework" "$THEOS/lib/iphone/rootless/$name.framework"
}

build_dependency GSCore https://github.com/qwer12345uui/GSCore.git migration/ios15-rootless-roothide
build_dependency Comet https://github.com/qwer12345uui/Comet.git migration/ios15-rootless-roothide
build_dependency GSWeather https://github.com/ginsudev/GSWeather.git main

ORION_STUB="$THEOS/vendor/lib/Orion.framework"
if [[ ! -d "$ORION_STUB" ]]; then
    echo "ERROR: Theos Orion framework stub is unavailable" >&2
    exit 1
fi
rm -rf "$THEOS/lib/Orion.framework" "$THEOS/lib/iphone/rootless/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/Orion.framework"
cp -R "$ORION_STUB" "$THEOS/lib/iphone/rootless/Orion.framework"

cd "$ROOT_DIR"
echo "== Build Dodo 5.0.1 rootless arm64e package =="
make package \
    ROOTLESS=1 ROOTHIDE=0 THEOS_PACKAGE_SCHEME=rootless \
    TARGET=iphone:clang:15.6:15.0 ARCHS=arm64e FINALPACKAGE=1 -j"$NCPU"

find "$ROOT_DIR/packages" -maxdepth 1 -type f -name '*.deb' -print -exec cp {} "$ROOT_DIR/candidates/" \;
if ! find "$ROOT_DIR/candidates" -maxdepth 1 -type f -name 'com.ginsu.dodo_5.0.1_iphoneos-arm64e.deb' | grep -q .; then
    echo "ERROR: expected Dodo 5.0.1 arm64e package was not produced" >&2
    find "$ROOT_DIR/candidates" -maxdepth 1 -type f -name '*.deb' -print >&2
    exit 1
fi

dpkg-deb -I "$ROOT_DIR/candidates/com.ginsu.dodo_5.0.1_iphoneos-arm64e.deb"
dpkg-deb -c "$ROOT_DIR/candidates/com.ginsu.dodo_5.0.1_iphoneos-arm64e.deb"
