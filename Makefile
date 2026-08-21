# Dodo iOS 15 / RootHide build entry point.
# The active Xcode path is overridden by ci/build-roothide.sh on CI.
export THEOS_PLATFORM_SDK_ROOT ?= /Applications/Xcode-15.4.0.app/Contents/Developer
export PREFIX ?= $(THEOS_PLATFORM_SDK_ROOT)/Toolchains/XcodeDefault.xctoolchain/usr/bin/
export ARCHS = arm64 arm64e
export TARGET ?= iphone:clang:latest:15.0

ROOTLESS ?= 0
ROOTHIDE ?= 0
INSTALL_TARGET_PROCESSES = SpringBoard
# Keep repair builds distinct from the user's original 5.0.0 installation.
PACKAGE_VERSION ?= 5.0.2+roothide2

ifeq ($(ROOTLESS),1)
ifneq ($(ROOTHIDE),0)
$(error ROOTLESS and ROOTHIDE cannot both be enabled)
endif
endif

ifeq ($(ROOTHIDE),1)
export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(ROOTLESS),1)
export THEOS_PACKAGE_SCHEME = rootless
endif

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Dodo
SUBPROJECTS += DodoPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
