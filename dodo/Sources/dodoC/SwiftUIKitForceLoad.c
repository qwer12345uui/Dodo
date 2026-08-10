// Xcode 15 emits this marker for Swift files that import UIKit. The older
// RootHide Theos linker rules can leave it unresolved even when libswiftUIKit
// is present. Keep the real overlay linked and provide the force-load marker.
#if defined(__APPLE__)
__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) __asm__("__swift_FORCE_LOAD_$_swiftUIKit");

__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) {}
#endif
