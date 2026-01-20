# إعدادات المعمارية والهدف
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

THEOS ?= ~/theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SovereignSecurity

# تم تغيير اسم الملف إلى SovereignCleanup لضمان عدم حدوث خطأ الترميز
SovereignSecurity_FILES = fishhook.c Mithril.mm SovereignCleanup.mm
SovereignSecurity_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreML
SovereignSecurity_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable

include $(THEOS_MAKE_PATH)/tweak.mk
