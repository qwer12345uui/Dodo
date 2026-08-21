// Xcode emits this marker when Swift code imports UIKit. Provide a local
// definition so Theos links RootHide arm64 and arm64e tweaks consistently.
#if defined(__APPLE__)
__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) __asm__("__swift_FORCE_LOAD_$_swiftUIKit");

__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) {}
#endif
