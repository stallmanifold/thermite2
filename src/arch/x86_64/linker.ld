ENTRY(_start)

SECTIONS {
	. = 1M;

	.boot : {
		/* 
		   GRUB expects the ELF header to be near the beginning
		   of the image. 
		*/
		KEEP(*(.multiboot_header))
	}

	.text : {
		*(.text, .text.*)
	}

	.rodata : {
        *(.rodata .rodata.*)
    }

    .data.rel.ro : {
        *(.data.rel.ro.local*) *(.data.rel.ro .data.rel.ro.*)
    }
}