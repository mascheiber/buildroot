################################################################################
#
# docker-cli
#
################################################################################

DOCKER_CLI_VERSION = 23.0.0
DOCKER_CLI_SITE = $(call github,docker,cli,v$(DOCKER_CLI_VERSION))

DOCKER_CLI_LICENSE = Apache-2.0
DOCKER_CLI_LICENSE_FILES = LICENSE

DOCKER_CLI_DEPENDENCIES = host-pkgconf

DOCKER_CLI_CPE_ID_VENDOR = docker
DOCKER_CLI_CPE_ID_PRODUCT = docker

DOCKER_CLI_TAGS = autogen
DOCKER_CLI_BUILD_TARGETS = cmd/docker
DOCKER_CLI_GOMOD = github.com/docker/cli

DOCKER_CLI_LDFLAGS = \
	-X $(DOCKER_CLI_GOMOD)/cli/version.GitCommit=$(DOCKER_CLI_VERSION) \
	-X $(DOCKER_CLI_GOMOD)/cli/version.Version=$(DOCKER_CLI_VERSION)

ifeq ($(BR2_PACKAGE_DOCKER_CLI_STATIC),y)
DOCKER_CLI_LDFLAGS += -extldflags '-static'
DOCKER_CLI_TAGS += osusergo netgo
DOCKER_CLI_GO_ENV = CGO_ENABLED=no
endif

# set the go.mod language version to go1.19
# remove the conflicting vendor/modules.txt
# https://github.com/moby/moby/issues/44618#issuecomment-1343565705
define DOCKER_ENGINE_CONFIGURE_CMDS
	cd $(@D); \
		$(HOST_GO_HOST_ENV) $(DOCKER_ENGINE_GO_ENV) \
		$(GO_BIN) mod edit -go=1.19 go.mod
	rm -f $(@D)/vendor/modules.txt
endef

DOCKER_CLI_INSTALL_BINS = $(notdir $(DOCKER_CLI_BUILD_TARGETS))

$(eval $(golang-package))
