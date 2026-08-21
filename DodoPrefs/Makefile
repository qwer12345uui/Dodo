include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DodoPrefs

ifeq ($(ROOTHIDE),1)
DodoPrefs_SWIFTFLAGS += -DROOTHIDE
DodoPrefs_CFLAGS += -DROOTHIDE
DodoPrefs_LDFLAGS += -rpath @loader_path/.jbroot/Library/Frameworks
DodoPrefs_LIBRARIES += roothide
else ifeq ($(ROOTLESS),1)
DodoPrefs_SWIFTFLAGS += -DROOTLESS
DodoPrefs_CFLAGS += -DROOTLESS
endif

XCODE_SWIFT_LIB = $(dir $(shell xcrun --sdk iphoneos -f swiftc))../lib/swift/iphoneos
DodoPrefs_FRAMEWORKS = SwiftUI
DodoPrefs_FILES = $(shell find Sources/DodoPrefs -name '*.swift') $(shell find Sources/DodoPrefsC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
DodoPrefs_SWIFTFLAGS += -ISources/DodoPrefsC/include
DodoPrefs_INSTALL_PATH = /Library/PreferenceBundles
DodoPrefs_LDFLAGS += -L$(XCODE_SWIFT_LIB)
DodoPrefs_LIBRARIES += swiftUIKit
DodoPrefs_CFLAGS += -fobjc-arc -ISources/DodoPrefsC/include

include $(THEOS_MAKE_PATH)/bundle.mk
