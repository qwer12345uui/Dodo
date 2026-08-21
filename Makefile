# Let Theos discover the active Xcode SDK instead of pinning a host-specific
# Xcode 15.4 path. This supports current macOS builders and local toolchains.
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.5

ROOTLESS ?= 0
INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION = 5.0.1

ifeq ($(ROOTLESS),1)
	export THEOS_PACKAGE_SCHEME = rootless
endif

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Dodo
SUBPROJECTS += DodoPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
