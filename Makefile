ROOTLESS ?= 0
ROOTHIDE ?= 0

ARCHS = arm64 arm64e
THEOS_DEVICE_IP = localhost -p 2222
INSTALL_TARGET_PROCESSES = SpringBoard
TARGET ?= iphone:clang:latest:15.0
# [FIX] 修复版版本号 4.2.4，与有问题的 4.2.3 区分
PACKAGE_VERSION = 4.2.4

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
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Dodo

Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift') $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_CFLAGS += -fobjc-arc -ISources/DodoC/include

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += dodo
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	# Append values to control file
	$(ECHO_NOTHING)sed -i '' \
	-e 's/\$${PKG_NAME_SUFFIX}/$(PKG_NAME_SUFFIX)/g' \
	$(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)
