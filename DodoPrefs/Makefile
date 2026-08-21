include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DodoPrefs

DodoPrefs_FRAMEWORKS = SwiftUI
DodoPrefs_FILES = $(shell find Sources/DodoPrefs -name '*.swift') $(shell find Sources/DodoPrefsC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
DodoPrefs_SWIFTFLAGS = -ISources/DodoPrefsC/include -F$(THEOS)/lib -I$(THEOS)/lib/GSCore.framework/Headers -I$(THEOS)/lib/Comet.framework/Headers -I$(THEOS)/lib/GSWeather.framework/Headers
DodoPrefs_LDFLAGS = -F$(THEOS)/lib -framework GSCore -framework Comet -framework GSWeather
DodoPrefs_INSTALL_PATH = /Library/PreferenceBundles
DodoPrefs_CFLAGS = -fobjc-arc -ISources/DodoPrefsC/include

include $(THEOS_MAKE_PATH)/bundle.mk
