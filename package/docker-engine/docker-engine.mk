################################################################################
#
# docker-engine
#
################################################################################

DOCKER_ENGINE_VERSION = 23.0.0
DOCKER_ENGINE_SITE = $(call github,moby,moby,v$(DOCKER_ENGINE_VERSION))

DOCKER_ENGINE_LICENSE = Apache-2.0
DOCKER_ENGINE_LICENSE_FILES = LICENSE

DOCKER_ENGINE_DEPENDENCIES = host-pkgconf
DOCKER_ENGINE_GOMOD = github.com/docker/docker

DOCKER_ENGINE_CPE_ID_VENDOR = docker
DOCKER_ENGINE_CPE_ID_PRODUCT = docker

DOCKER_ENGINE_LDFLAGS = \
	-X $(DOCKER_ENGINE_GOMOD)/dockerversion.BuildTime="" \
	-X $(DOCKER_ENGINE_GOMOD)/dockerversion.GitCommit="buildroot" \
	-X $(DOCKER_ENGINE_GOMOD)/dockerversion.IAmStatic="false" \
	-X $(DOCKER_ENGINE_GOMOD)/dockerversion.InitCommitID="" \
	-X $(DOCKER_ENGINE_GOMOD)/dockerversion.Version="$(DOCKER_ENGINE_VERSION)"

DOCKER_ENGINE_TAGS = cgo exclude_graphdriver_zfs
DOCKER_ENGINE_BUILD_TARGETS = cmd/dockerd cmd/docker-proxy

ifeq ($(BR2_PACKAGE_LIBAPPARMOR),y)
DOCKER_ENGINE_DEPENDENCIES += libapparmor
endif

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
DOCKER_ENGINE_DEPENDENCIES += libseccomp
endif

ifeq ($(BR2_INIT_SYSTEMD),y)
DOCKER_ENGINE_DEPENDENCIES += systemd
DOCKER_ENGINE_TAGS += systemd journald
endif
ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_EXPERIMENTAL),y)
DOCKER_ENGINE_TAGS += experimental
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
DOCKER_ENGINE_DEPENDENCIES += btrfs-progs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_btrfs
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
DOCKER_ENGINE_DEPENDENCIES += lvm2
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_devicemapper
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_VFS),y)
DOCKER_ENGINE_DEPENDENCIES += gvfs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_vfs
endif

# create the go.mod file with language version go1.19
# remove the conflicting vendor/modules.txt
# https://github.com/moby/moby/issues/44618#issuecomment-1343565705
define DOCKER_ENGINE_FIX_VENDORING
	printf "module $(DOCKER_ENGINE_GOMOD)\n\ngo 1.19\n" > $(@D)/go.mod
	rm -f $(@D)/vendor/modules.txt
endef
DOCKER_ENGINE_POST_EXTRACT_HOOKS += DOCKER_ENGINE_FIX_VENDORING

DOCKER_ENGINE_INSTALL_BINS = $(notdir $(DOCKER_ENGINE_BUILD_TARGETS))

define DOCKER_ENGINE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.service \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.service
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.socket \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.socket
endef

define DOCKER_ENGINE_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 755 package/docker-engine/S60dockerd \
		$(TARGET_DIR)/etc/init.d/S60dockerd
endef

define DOCKER_ENGINE_USERS
	- - docker -1 * - - - Docker Application Container Framework
endef

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
define DOCKER_ENGINE_DRIVER_BTRFS_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_BTRFS_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BTRFS_FS_POSIX_ACL)
endef
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
define DOCKER_ENGINE_DRIVER_DM_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_MD)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BLK_DEV_DM)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MD_THIN_PROVISIONING)
endef
endif

# based on contrib/check-config.sh
define DOCKER_ENGINE_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_POSIX_MQUEUE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUPS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MEMCG)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_SCHED)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_FREEZER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CPUSETS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_DEVICE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_CPUACCT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NAMESPACES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_UTS_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IPC_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_PID_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_ADVANCED)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NF_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_ADDRTYPE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_IPVS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_IPTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_FILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_NAT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_TARGET_MASQUERADE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET_CORE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_VETH)
	$(call KCONFIG_ENABLE_OPT,CONFIG_OVERLAY_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_KEYS)
	$(DOCKER_ENGINE_DRIVER_BTRFS_LINUX_CONFIG_FIXUPS)
	$(DOCKER_ENGINE_DRIVER_DM_LINUX_CONFIG_FIXUPS)
endef

$(eval $(golang-package))
