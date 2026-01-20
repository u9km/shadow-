# إعدادات الهدف والمعمارية
TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1

# السماح لـ GitHub بتحديد مسار Theos تلقائياً
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SovereignSecurity

# [span_2](start_span)ربط الملفات المصدرية بناءً على هيكل مشروعك[span_2](end_span)
SovereignSecurity_FILES = fishhook.c $(wildcard 防禁令/*.mm)
SovereignSecurity_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreML
SovereignSecurity_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable

include $(THEOS_MAKE_PATH)/tweak.mk
