THEOS=/var/mobile/theos

ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
IGNORE_WARNINGS = 0

#THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SovereignSecurity

# نستخدم ملف واحد فقط لأننا دمجنا كل شيء فيه
SovereignSecurity_FILES = $(wildcard 防禁令/*.mm) fishhook.c
SovereignSecurity_FRAMEWORKS = UIKit CoreML Foundation Security
SovereignSecurity_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
