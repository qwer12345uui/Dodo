MODULES = shook
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Dodo

DODO_FRAMEWORK_ROOT = $(THEOS)/lib
ifeq ($(ROOTHIDE),1)
DODO_FRAMEWORK_ROOT = $(THEOS)/lib/iphone/roothide
Dodo_SWIFTFLAGS += -DROOTHIDE
Dodo_CFLAGS += -DROOTHIDE
Dodo_LDFLAGS += -rpath @loader_path/.jbroot/Library/Frameworks
Dodo_LIBRARIES += roothide
else ifeq ($(ROOTLESS),1)
DODO_FRAMEWORK_ROOT = $(THEOS)/lib/iphone/rootless
Dodo_SWIFTFLAGS += -DROOTLESS
Dodo_CFLAGS += -DROOTLESS
endif

XCODE_SWIFT_LIB = $(dir $(shell xcrun --sdk iphoneos -f swiftc))../lib/swift/iphoneos
Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift')
Dodo_FILES += $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_FILES += $(shell find Sources/DodoLoader -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_SWIFTFLAGS += -ISources/DodoC/include -F$(DODO_FRAMEWORK_ROOT) -I$(DODO_FRAMEWORK_ROOT)/GSCore.framework/Headers -I$(DODO_FRAMEWORK_ROOT)/Comet.framework/Headers -I$(DODO_FRAMEWORK_ROOT)/GSWeather.framework/Headers
Dodo_LDFLAGS += -F$(DODO_FRAMEWORK_ROOT) -L$(XCODE_SWIFT_LIB) -framework GSCore -framework Comet -framework GSWeather
Dodo_LIBRARIES += swiftUIKit
Dodo_CFLAGS += -fobjc-arc -ISources/DodoC/include -ISources/DodoLoader/include

include $(THEOS_MAKE_PATH)/tweak.mk
