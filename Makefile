ROOTLESS ?= 0

ARCHS = arm64 arm64e
THEOS_DEVICE_IP = localhost -p 2222
INSTALL_TARGET_PROCESSES = SpringBoard
TARGET = iphone:clang:17.0.2:14.5
# [FIX] 修复版版本号 4.2.4，与有问题的 4.2.3 区分
PACKAGE_VERSION = 4.2.4

Dodo_SWIFTFLAGS = -ISources/DodoC/include

# Rootless / Rootful settings
ifeq ($(ROOTLESS),1)
    THEOS_PACKAGE_SCHEME = rootless
    # Control
    PKG_NAME_SUFFIX = (Rootless)
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Dodo

Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift') $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_CFLAGS = -fobjc-arc -ISources/DodoC/include

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += dodo
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	# Append values to control file
	$(ECHO_NOTHING)sed -i '' \
	-e 's/\$${PKG_NAME_SUFFIX}/$(PKG_NAME_SUFFIX)/g' \
	$(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)
