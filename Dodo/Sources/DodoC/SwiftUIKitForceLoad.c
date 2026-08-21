// Xcode emits this marker for Swift files that import UIKit. The Theos linker
// can leave it unresolved even when the actual Swift UIKit overlay is linked.
#if defined(__APPLE__)
__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) __asm__("__swift_FORCE_LOAD_$_swiftUIKit");

__attribute__((used, visibility("default")))
void DodoSwiftUIKitForceLoad(void) {}
#endif
