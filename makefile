export ARCHS = arm64
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AntiBanProject

AntiBanProject_FILES = Tweak.x
AntiBanProject_FRAMEWORKS = UIKit Foundation Security
AntiBanProject_CFLAGS = -fobjc-arc -Wno-error

include $(THEOS)/makefiles/tweak.mk
