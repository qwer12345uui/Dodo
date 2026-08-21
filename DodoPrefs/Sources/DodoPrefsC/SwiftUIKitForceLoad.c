// Provide the Swift UIKit force-load marker required by the preferences bundle.
#if defined(__APPLE__)
__attribute__((used, visibility("default")))
void DodoPrefsSwiftUIKitForceLoad(void) __asm__("__swift_FORCE_LOAD_$_swiftUIKit");

__attribute__((used, visibility("default")))
void DodoPrefsSwiftUIKitForceLoad(void) {}
#endif
