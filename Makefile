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
### Build configuration parameters
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

# Source code files
LINKER_SCRIPT := $(patsubst %, $(ARCH_DIRECTORY)/%, $(ARCH_LINKER_SCRIPT))
GRUB_CFG := $(patsubst %, $(ARCH_DIRECTORY)/%, $(ARCH_GRUB_CFG))
ASM_SOURCE_FILES += $(patsubst %, $(ARCH_DIRECTORY)/%, $(ARCH_ASM_SOURCE_FILES))
ASM_OBJECT_FILES += $(patsubst $(ARCH_DIRECTORY)/%.asm, build/arch/$(ARCH)/%.o, $(ASM_SOURCE_FILES))

#
### Top-level targets
# 
.PHONY: default all build run clean

default: all

all: $(KERNEL)

build: $(ISO)

clean:
	@rm -r $(BUILD_ROOT)


run: $(ISO)
	@qemu-system-x86_64 -s -cdrom $(ISO)

#
### Dry-run target.
#
# This would be what the build tool would output if it actually ran.
#
.PHONY: dry-run
dry-run:
	@echo "Configuration Info:"
	@echo "==================================="
	@echo "ARCH = $(ARCH)"
	@echo "SOURCE_ROOT = $(SOURCE_ROOT)"
	@echo "BUILD_ROOT = $(BUILD_ROOT)"
	@echo "KERNEL = $(KERNEL)"
	@echo "ISO = $(ISO)"
	@echo "LINKER_SCRIPT = $(LINKER_SCRIPT)"
	@echo "GRUB_CFG = $(GRUB_CFG)"
	@echo "ASM_SOURCE_FILES = \"$(ASM_SOURCE_FILES)\""
	@echo "ASM_OBJECT_FILES = \"$(ASM_OBJECT_FILES)\""
	@echo "==================================="

#
### File pattern specific targets.
#
$(ISO): $(KERNEL) $(GRUB_CFG)
	@mkdir -p $(BUILD_ROOT)/isofiles/boot/grub
	@cp $(KERNEL) build/isofiles/boot/kernel.bin
	@cp $(GRUB_CFG) build/isofiles/boot/grub
	@grub-mkrescue -o $(ISO) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(KERNEL): $(ASM_OBJECT_FILES) $(LINKER_SCRIPT)
	@echo $(ASM_OBJECT_FILES)
	@ld -n -T $(LINKER_SCRIPT) -o $(KERNEL) $(ASM_OBJECT_FILES)

build/arch/$(ARCH)/%.o: $(ARCH_DIRECTORY)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -f elf64 $< -o $@
