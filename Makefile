export TARGET := iphone:clang:latest:13.0
export ARCHS := arm64
export THEOS_PACKAGE_SCHEME := rootless
INSTALL_TARGET_PROCESSES = RoyalMatch

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RoyalIAPHook
RoyalIAPHook_FILES = Tweak.xm
RoyalIAPHook_FRAMEWORKS = UIKit QuartzCore Foundation StoreKit
RoyalIAPHook_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
RoyalIAPHook_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
