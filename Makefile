#
# Copyright 2017 Christopher Blanchard. See the README.md file at the top-level
# directory of this distribution.
#
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.
#

#
### Build parameters
#
ARCH ?= x86_64

ifndef SOURCE_ROOT
	SOURCE_ROOT=.
	export SOURCE_ROOT
endif

include $(SOURCE_ROOT)/src/arch/$(ARCH)/Makefile

BUILD_ROOT := $(SOURCE_ROOT)/build

# Binary targets for building the OS.
KERNEL := $(BUILD_ROOT)/kernel-$(ARCH).bin
ISO := $(BUILD_ROOT)/os-$(ARCH).iso

LINKER_SCRIPT := $(ARCH_LINKER_SCRIPT)
GRUB_CFG := $(ARCH_GRUB_CFG)
ASM_SOURCE_FILES := $(ARCH_ASM_SOURCE_FILES)
ASM_OBJECT_FILES := $(patsubst $(ARCH_DIRECTORY)/%.asm, \
	build/arch/$(ARCH)/%.o, $(assembly_source_files))

.PHONY: all clean run build

all:


clean:
	@rm -r $(BUILD_ROOT)


run:
	@qemu-system-x86_64 -s -cdrom $(ISO)

