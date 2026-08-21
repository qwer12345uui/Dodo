export THEOS_PLATFORM_SDK_ROOT=/Applications/Xcode-15.4.0.app/Contents/Developer
export PREFIX=$(THEOS_PLATFORM_SDK_ROOT)/Toolchains/XcodeDefault.xctoolchain/usr/bin/
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:16.5:14.5

ROOTLESS ?= 0
<<<<<<< HEAD
ROOTHIDE ?= 0

ARCHS = arm64 arm64e
THEOS_DEVICE_IP = localhost -p 2222
INSTALL_TARGET_PROCESSES = SpringBoard
TARGET ?= iphone:clang:latest:15.0
# Push-notification stability repair for iPhone XS Max / iOS 15 RootHide.
# A newer version avoids replacing the user's existing 5.0.0 package in place.
PACKAGE_VERSION = 5.0.1+roothide1

Dodo_SWIFTFLAGS = -ISources/DodoC/include

# Standard rootless and RootHide deliberately use distinct package schemes.
ifeq ($(ROOTLESS),1)
ifneq ($(ROOTHIDE),0)
$(error ROOTLESS and ROOTHIDE cannot both be enabled)
endif
endif

ifeq ($(ROOTHIDE),1)
	THEOS_PACKAGE_SCHEME = roothide
	Dodo_SWIFTFLAGS += -DROOTHIDE
	Dodo_CFLAGS += -DROOTHIDE
	Dodo_LDFLAGS += -rpath @loader_path/.jbroot/Library/Frameworks
	Dodo_LIBRARIES += roothide
	PKG_NAME_SUFFIX = (RootHide)
else ifeq ($(ROOTLESS),1)
	THEOS_PACKAGE_SCHEME = rootless
	Dodo_SWIFTFLAGS += -DROOTLESS
	Dodo_CFLAGS += -DROOTLESS
	PKG_NAME_SUFFIX = (Rootless)
=======
INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION = 5.0.0

ifeq ($(ROOTLESS),1)
	export THEOS_PACKAGE_SCHEME = rootless
>>>>>>> upstream/main
endif

include $(THEOS)/makefiles/common.mk

<<<<<<< HEAD
TWEAK_NAME = Dodo

# Keep the Swift UIKit overlay discoverable for arm64/arm64e Theos links.
XCODE_SWIFT_LIB = $(dir $(shell xcrun --sdk iphoneos -f swiftc))../lib/swift/iphoneos
Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift') $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_LDFLAGS += -L$(XCODE_SWIFT_LIB)
Dodo_LIBRARIES += swiftUIKit
Dodo_CFLAGS += -fobjc-arc -ISources/DodoC/include

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += dodo
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	# Append values to control file
	$(ECHO_NOTHING)sed -i '' \
	-e 's/\$${PKG_NAME_SUFFIX}/$(PKG_NAME_SUFFIX)/g' \
	$(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)
=======
SUBPROJECTS += Dodo
SUBPROJECTS += DodoPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
>>>>>>> upstream/main
