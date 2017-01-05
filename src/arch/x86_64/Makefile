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

ARCH_DIRECTORY += src/arch/x86_64

ARCH_LINKER_SCRIPT    += x86_64/linker.ld
ARCH_ASM_SOURCE_FILES += x86_64/multiboot_header.asm \
			 x86_64/boot.asm
ARCH_BOOTLOADER_CONFIG_DIR += x86_64/boot

ARCH_GRUB_CFG := $(ARCH_BOOTLOADER_CONFIG_DIR)/grub/grub.cfg