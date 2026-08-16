ROOTLESS ?= 0
ROOTHIDE ?= 0

ARCHS = arm64 arm64e
TARGET ?= iphone:clang:latest:15.0

ifeq ($(ROOTLESS),1)
ifneq ($(ROOTHIDE),0)
$(error ROOTLESS and ROOTHIDE cannot both be enabled)
endif
endif

ifeq ($(ROOTHIDE),1)
	THEOS_PACKAGE_SCHEME = roothide
	dodo_SWIFTFLAGS += -DROOTHIDE
	dodo_CFLAGS += -DROOTHIDE
	dodo_LDFLAGS += -rpath @loader_path/.jbroot/Library/Frameworks
else ifeq ($(ROOTLESS),1)
	THEOS_PACKAGE_SCHEME = rootless
	dodo_SWIFTFLAGS += -DROOTLESS
	dodo_CFLAGS += -DROOTLESS
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = dodo

dodo_FILES = $(shell find Sources/dodo -name '*.swift') $(shell find Sources/dodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
dodo_SWIFTFLAGS += -ISources/dodoC/include
dodo_INSTALL_PATH = /Library/PreferenceBundles
dodo_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
