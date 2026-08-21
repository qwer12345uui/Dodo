MODULES = shook

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Dodo

Dodo_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices SpringBoardFoundation MediaRemote MobileTimer SpringBoardUI CoverSheet WeatherFoundation
Dodo_FILES = $(shell find Sources/Dodo -name '*.swift')
Dodo_FILES += $(shell find Sources/DodoC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_FILES += $(shell find Sources/DodoLoader -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Dodo_SWIFTFLAGS = -ISources/DodoC/include
Dodo_CFLAGS = -fobjc-arc -ISources/DodoC/include -ISources/DodoLoader/include

include $(THEOS_MAKE_PATH)/tweak.mk
#SUBPROJECTS += dodo
#include $(THEOS_MAKE_PATH)/aggregate.mk
