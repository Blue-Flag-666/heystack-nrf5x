.PHONY: all help

HAS_DEBUG ?= 0
HAS_BATTERY ?= 1
MAX_KEYS ?= 500
KEY_ROTATION_INTERVAL ?= 3600
ADVERTISING_INTERVAL ?= 3000
RANDOM_ROTATE_KEYS ?= 1

GNU_INSTALL_ROOT ?= $(CURDIR)/nrf-sdk/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi

TARGETS := \
	nrf51822_xxac \
	nrf51822_xxac-dcdc \
	nrf52805_xxaa \
	nrf52805_xxaa-dcdc \
	nrf52810_xxaa \
	nrf52810_xxaa-dcdc \
	nrf52832_xxaa \
	nrf52832_xxaa-dcdc \
	nrf52832_yj17024

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all        - build all targets"
	@echo "  clean      - clean all targets"

# Define a recipe to build each target individually
define build_target
.PHONY: $(1)
DIR_$(1) := $(shell echo $(1) | cut -d'_' -f1)

$(1):
	$$(MAKE) -C $$(DIR_$(1))/armgcc \
		GNU_INSTALL_ROOT=$(if $(findstring nrf51,$(1)),$(GNU_INSTALL_ROOT),"$(GNU_INSTALL_ROOT)/bin/") \
		MAX_KEYS=$(MAX_KEYS) \
		HAS_DEBUG=$(HAS_DEBUG) \
		HAS_BATTERY=$(HAS_BATTERY) \
		KEY_ROTATION_INTERVAL=$(KEY_ROTATION_INTERVAL) \
		ADVERTISING_INTERVAL=$(ADVERTISING_INTERVAL) \
		RANDOM_ROTATE_KEYS=$(RANDOM_ROTATE_KEYS) \
		$(1) bin_$(1)

	mkdir -p ./release
	cp $$(DIR_$(1))/armgcc/_build/*_s???.bin ./release/
	@echo "# Build options for $(1)" > ./release/$(1).txt
	@echo "GNU_INSTALL_ROOT=$$(shell basename $$(GNU_INSTALL_ROOT))" >> ./release/$(1).txt
	@echo "MAX_KEYS=$(MAX_KEYS)" >> ./release/$(1).txt
	@echo "HAS_DEBUG=$(HAS_DEBUG)" >> ./release/$(1).txt
	@echo "HAS_BATTERY=$(HAS_BATTERY)" >> ./release/$(1).txt
	@echo "KEY_ROTATION_INTERVAL=$(KEY_ROTATION_INTERVAL)" >> ./release/$(1).txt
	@echo "ADVERTISING_INTERVAL=$(ADVERTISING_INTERVAL)" >> ./release/$(1).txt
	@echo "RANDOM_ROTATE_KEYS=$(RANDOM_ROTATE_KEYS)" >> ./release/$(1).txt


$(1)-clean:
	$$(MAKE) -C $$(DIR_$(1))/armgcc clean \
		GNU_INSTALL_ROOT=$(if $(findstring nrf51,$(1)),$(GNU_INSTALL_ROOT),"$(GNU_INSTALL_ROOT)/bin/")

endef

# Generate rules for each target in the TARGETS list
$(foreach target,$(TARGETS),$(eval $(call build_target,$(target))))

# Define all target to depend on all individual targets
all: $(TARGETS)

clean: $(foreach target,$(TARGETS),$(target)-clean)
	rm -rf ./release


.PHONY: sdk sdk-download sdk-unzip sdk-patch sdk-install
sdk: sdk-download sdk-unzip sdk-patch sdk-install

sdk-download:
	mkdir -p ./nrf-sdk
	wget -c https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/sdks/nrf5/binaries/nrf5_sdk_17.1.0_ddde560.zip -O ./nrf-sdk/nRF5_SDK_17.1.0_ddde560.zip
	wget -c https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/sdks/nrf5/binaries/nrf5sdk1230.zip -O ./nrf-sdk/nRF5_SDK_12.3.0_d7731ad.zip
	wget -c https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools_10.24.2_amd64.deb -O ./nrf-sdk/nrf-command-line-tools_10.24.2_amd64.deb
	wget -c https://github.com/NordicSemiconductor/nrfx/releases/download/v2.11.0/nrfx-v2.11.0-2527e3c8.zip -O ./nrf-sdk/nrfx-v2.11.0-2527e3c8.zip
	wget -c https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz -O ./nrf-sdk/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz
	wget -c https://devzone.nordicsemi.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-00-13/SDK_5F00_v17.0.0_5F00_nRF52805_5F00_Patch.zip -O ./nrf-sdk/SDK_v17.0.0_nRF52805_Patch.zip

sdk-unzip:
	mkdir -p ./nrf-sdk/nrfx-v2.11.0-2527e3c8
	cd ./nrf-sdk && unzip -qo nRF5_SDK_17.1.0_ddde560.zip
	cd ./nrf-sdk && unzip -qo nRF5_SDK_12.3.0_d7731ad.zip
	cd ./nrf-sdk/nrfx-v2.11.0-2527e3c8 && unzip -qo ../nrfx-v2.11.0-2527e3c8.zip
	cd ./nrf-sdk && tar -xf arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz
	cd ./nrf-sdk && unzip -qo SDK_v17.0.0_nRF52805_Patch.zip

sdk-patch:
	cp -f ./nrf-sdk/SDK_v16.0.0_nRF52805_Patch/nrf_bootloader_info.c ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/components/libraries/bootloader/nrf_bootloader_info.c
	cp -f ./nrf-sdk/SDK_v16.0.0_nRF52805_Patch/nrf_dfu_types.h ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/components/libraries/bootloader/dfu/nrf_dfu_types.h
	cp -f ./nrf-sdk/nrfx-v2.11.0-2527e3c8/soc/nrfx_irqs* ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/soc/
	cp -f ./nrf-sdk/nrfx-v2.11.0-2527e3c8/soc/nrfx_coredep.h ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/soc/
	cp -f ./nrf-sdk/nrfx-v2.11.0-2527e3c8/drivers/nrfx_common.h ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/drivers/nrfx_common.h
	cp -f ./nrf-sdk/nrfx-v2.11.0-2527e3c8/drivers/src/prs/nrfx_prs.h ./nrf-sdk/nRF5_SDK_17.1.0_ddde560/modules/nrfx/drivers/src/prs/nrfx_prs.h

sdk-install:
	sudo dpkg -i ./nrf-sdk/nrf-command-line-tools_10.24.2_amd64.deb
	sudo apt install /opt/nrf-command-line-tools/share/JLink_Linux_V794e_x86_64.deb --fix-broken
	cp -f ./nrf-sdk/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-none-eabi/bin/objcopy ./tools/objcopy