ROOTHIDE ?= 0
ROOTLESS ?= 0

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0

ifeq ($(ROOTHIDE),1)
	dodo_SWIFTFLAGS += -DROOTHIDE
	dodo_CFLAGS += -DROOTHIDE
else ifeq ($(ROOTLESS),1)
	dodo_SWIFTFLAGS += -DROOTLESS
	dodo_CFLAGS += -DROOTLESS
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = dodo

dodo_FILES = $(shell find Sources/dodo -name '*.swift') $(shell find Sources/dodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
dodo_SWIFTFLAGS += -ISources/dodoC/include
dodo_INSTALL_PATH = /Library/PreferenceBundles
dodo_CFLAGS += -fobjc-arc
dodo_LIBRARIES += roothide

include $(THEOS_MAKE_PATH)/bundle.mk
