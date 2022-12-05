################################################################################
#
# conmon
#
################################################################################

CONMON_VERSION = 2.1.3
CONMON_SITE = $(call github,containers,conmon,v$(CONMON_VERSION))
CONMON_LICENSE = Apache-2.0
CONMON_LICENSE_FILES = LICENSE

CONMON_DEPENDENCIES += host-pkgconf libglib2

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
CONMON_ENABLE_SECCOMP = 1
CONMON_DEPENDENCIES += libseccomp
else
CONMON_ENABLE_SECCOMP = 0
endif

define CONMON_CONFIGURE_CMDS
	printf '#!/bin/bash\necho "$(CONMON_ENABLE_SECCOMP)"\n' > \
		$(@D)/hack/seccomp-notify.sh
	chmod +x $(@D)/hack/seccomp-notify.sh
endef

define CONMON_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" -C $(@D) bin/conmon
endef

define CONMON_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bin/conmon $(TARGET_DIR)/usr/bin/conmon
endef

$(eval $(generic-package))
