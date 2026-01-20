# إعدادات المعمارية والهدف لعام 2026
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

# السماح لـ GitHub بتعريف المسار تلقائياً
THEOS ?= ~/theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SovereignSecurity

# [span_0](start_span)استدعاء كافة الملفات البرمجية الموجودة في المجلد الرئيسي[span_0](end_span)
SovereignSecurity_FILES = fishhook.c Mithril.mm 循环删ano.mm
# [span_1](start_span)[span_2](start_span)إضافة المكتبات الضرورية بناءً على الأكواد المرفوعة[span_1](end_span)[span_2](end_span)
SovereignSecurity_FRAMEWORKS = UIKit Foundation Security CoreGraphics QuartzCore CoreML
# [span_3](start_span)إعدادات التجميع لضمان استقرار الحقن وتجاهل التحذيرات[span_3](end_span)
SovereignSecurity_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable

include $(THEOS_MAKE_PATH)/tweak.mk
