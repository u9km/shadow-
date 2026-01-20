# إعدادات المعمارية والهدف (دعم arm64e أساسي لعام 2026)
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
DEBUG = 0
FINALPACKAGE = 1

# تعريف المسار الافتراضي لـ Theos إذا لم يكن موجوداً (للعمل على GitHub)
THEOS ?= ~/theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SovereignSecurity

# تحديد الملفات المصدرية:
# 1. ملفات المجلد الأساسي (Mithril.mm و fishhook.c)
# 2. ملفات مجلد الحماية (防禁令)
SovereignSecurity_FILES = Mithril.mm fishhook.c $(wildcard 防禁令/*.mm)

# [span_2](start_span)[span_3](start_span)المكتبات المطلوبة بناءً على الأكواد المقدمة[span_2](end_span)[span_3](end_span)
# تم إضافة QuartzCore و CoreGraphics لدعم الواجهة الرسومية (Overlay)
SovereignSecurity_FRAMEWORKS = UIKit Foundation Security CoreGraphics QuartzCore CoreML

# إعدادات التجميع (CFLAGS)
# -fobjc-arc: لضمان إدارة الذاكرة تلقائياً ومنع الكراش
# -Wno-deprecated-declarations: لتجاهل تحذيرات الكود القديم في iOS 18
SovereignSecurity_CFLAGS = -fobjc-arc -O3 -Wno-deprecated-declarations -Wno-unused-variable

# إعدادات الربط المتقدمة (LDFLAGS) لضمان الاستقرار في السايدلود
SovereignSecurity_LDFLAGS = -Wl,-segalign,0x4000

include $(THEOS_MAKE_PATH)/tweak.mk

# تنظيف وقتل عمليات اللعبة بعد التثبيت (للتجربة اليدوية)
after-install::
	install.exec "killall -9 ShadowTrackerExtra"
