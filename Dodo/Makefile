MODULES = shook

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Dodo
XCODE_SWIFT_LIB = $(dir $(shell xcrun --sdk iphoneos -f swiftc))../lib/swift/iphoneos
Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift')
Dodo_FILES += $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_FILES += $(shell find Sources/DodoLoader -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
# The restored weather implementation imports the separately packaged runtime
# frameworks. Expose their module maps to Swift and link them into the tweak.
Dodo_SWIFTFLAGS = -ISources/DodoC/include -F$(THEOS)/lib -I$(THEOS)/lib/GSCore.framework/Headers -I$(THEOS)/lib/Comet.framework/Headers -I$(THEOS)/lib/GSWeather.framework/Headers
Dodo_LDFLAGS = -F$(THEOS)/lib -F$(THEOS)/sdks/iPhoneOS15.6.sdk/System/Library/PrivateFrameworks -L$(XCODE_SWIFT_LIB) -framework GSCore -framework Comet -framework GSWeather
Dodo_LIBRARIES = swiftUIKit
Dodo_CFLAGS = -fobjc-arc -ISources/DodoC/include -ISources/DodoLoader/include

include $(THEOS_MAKE_PATH)/tweak.mk
#SUBPROJECTS += dodo
#include $(THEOS_MAKE_PATH)/aggregate.mk
