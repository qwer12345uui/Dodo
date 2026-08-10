#!/bin/bash
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
DEPS_DIR="${RUNNER_TEMP:-/tmp}/dodo-roothide-deps"
THEOS="${THEOS:-$ROOT_DIR/theos}"
export THEOS
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

rm -rf "$DEPS_DIR"
mkdir -p "$DEPS_DIR" "$THEOS/lib/iphone/roothide" "$THEOS/sdks" "$ROOT_DIR/Layout/Library/Frameworks"

echo "== Toolchain =="
xcodebuild -version
swiftc --version
clang --version | head -n 1

echo "== Install patched iOS 15.6 SDK =="
SDK_REPO="$DEPS_DIR/theos-sdks"
git clone --depth 1 --filter=blob:none --sparse https://github.com/theos/sdks.git "$SDK_REPO"
git -C "$SDK_REPO" sparse-checkout set iPhoneOS15.6.sdk
rm -rf "$THEOS/sdks/iPhoneOS15.6.sdk"
cp -R "$SDK_REPO/iPhoneOS15.6.sdk" "$THEOS/sdks/iPhoneOS15.6.sdk"
find "$THEOS/sdks/iPhoneOS15.6.sdk" -path '*SpringBoard.framework*' -print | head

echo "== Fetch dependencies =="
git clone --depth 1 https://github.com/ginsudev/GSCore.git "$DEPS_DIR/GSCore"
git clone --depth 1 https://github.com/ginsudev/Comet.git "$DEPS_DIR/Comet"
git clone --depth 1 https://github.com/ginsudev/GSWeather.git "$DEPS_DIR/GSWeather"

# GSCore used a fixed /var/jb path. RootHide randomizes jbroot, so resolve it
# through the .jbroot symlink placed next to each loaded Mach-O framework.
cat > "$DEPS_DIR/GSCore/GSCore/Extensions/String+Extensions.swift" <<'SWIFT'
import Foundation

private final class GSCorePathToken: NSObject {}

public extension String {
    var rootify: Self {
        guard first == "/" else { return self }
        #if ROOTHIDE
        let frameworkDirectory = Bundle(for: GSCorePathToken.self).bundlePath
        return frameworkDirectory + "/.jbroot" + self
        #elseif ROOTLESS
        return "/var/jb/" + self.dropFirst()
        #else
        return self
        #endif
    }

    func localize(bundle: Bundle) -> Self {
        String(NSLocalizedString(self, bundle: bundle, comment: ""))
    }
}

internal extension String {
    var localized: Self { localize(bundle: .gsCore) }
}
SWIFT

copy_framework() {
    local name="$1"
    local source=""
    local safe_copy="$DEPS_DIR/.framework-cache/$name.framework"

    source="$(find "$THEOS/lib" "$DEPS_DIR" -type d -name "$name.framework" ! -path '*dSYM*' 2>/dev/null | head -n 1 || true)"
    if [[ -z "$source" ]]; then
        echo "ERROR: $name.framework was not produced"
        find "$DEPS_DIR" -maxdepth 8 -name '*.framework' -print || true
        exit 1
    fi

    echo "Using $name framework: $source"
    rm -rf "$safe_copy"
    mkdir -p "$(dirname "$safe_copy")"
    cp -R "$source" "$safe_copy"

    rm -rf \
        "$THEOS/lib/$name.framework" \
        "$THEOS/lib/iphone/roothide/$name.framework" \
        "$ROOT_DIR/Layout/Library/Frameworks/$name.framework"
    cp -R "$safe_copy" "$THEOS/lib/$name.framework"
    cp -R "$safe_copy" "$THEOS/lib/iphone/roothide/$name.framework"
    cp -R "$safe_copy" "$ROOT_DIR/Layout/Library/Frameworks/$name.framework"

    otool -D "$safe_copy/$name" || true
    otool -L "$safe_copy/$name" || true
}

build_xcode_framework() {
    local name="$1"
    local directory="$2"
    local install_var="$3"
    local move_var="$4"
    echo "== Build $name for RootHide =="
    make -C "$directory" clean || true
    make -C "$directory" package \
        THEOS_PACKAGE_SCHEME=roothide \
        ROOTHIDE=1 ROOTLESS=0 FINALPACKAGE=1 \
        "$install_var=/Library/Frameworks" \
        "$move_var=$THEOS/lib/iphone/roothide/" \
        "${name}_XCODEFLAGS=SWIFT_ACTIVE_COMPILATION_CONDITIONS=ROOTHIDE" \
        -j"$NCPU"
    copy_framework "$name"
}

build_xcode_framework GSCore "$DEPS_DIR/GSCore" GSCORE_INSTALL_PATH MOVE_TO_THEOS_PATH
build_xcode_framework Comet "$DEPS_DIR/Comet" COMET_INSTALL_PATH MOVE_TO_THEOS_PATH
build_xcode_framework GSWeather "$DEPS_DIR/GSWeather" GSWEATHER_INSTALL_PATH MOVE_TO_THEOS_PATH

# The RootHide Theos fork ships a pre-patched Orion framework in vendor/lib.
ORION_SOURCE="$(find "$THEOS/vendor/lib" "$THEOS/lib" -type d -name 'Orion.framework' ! -path '*rootless*' 2>/dev/null | head -n 1 || true)"
if [[ -z "$ORION_SOURCE" ]]; then
    echo "ERROR: RootHide Orion.framework not found"
    exit 1
fi
ORION_CACHE="$DEPS_DIR/.framework-cache/Orion.framework"
rm -rf "$ORION_CACHE"
cp -R "$ORION_SOURCE" "$ORION_CACHE"
rm -rf "$THEOS/lib/Orion.framework" "$THEOS/lib/iphone/roothide/Orion.framework" "$ROOT_DIR/Layout/Library/Frameworks/Orion.framework"
cp -R "$ORION_CACHE" "$THEOS/lib/Orion.framework"
cp -R "$ORION_CACHE" "$THEOS/lib/iphone/roothide/Orion.framework"
cp -R "$ORION_CACHE" "$ROOT_DIR/Layout/Library/Frameworks/Orion.framework"
otool -D "$ORION_CACHE/Orion" || true

echo "== Build Dodo RootHide package =="
cd "$ROOT_DIR"
rm -rf .theos packages
make package \
    ROOTHIDE=1 ROOTLESS=0 \
    THEOS_PACKAGE_SCHEME=roothide \
    TARGET=iphone:clang:latest:15.0 \
    FINALPACKAGE=1 \
    -j"$NCPU"

echo "== Validate output =="
ls -lah packages/*.deb
find .theos -type f \( -name 'Dodo.dylib' -o -name 'dodo' \) -print -exec otool -L {} \; || true
