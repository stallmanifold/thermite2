ENTRY(start)

SECTIONS {
	. = 1M;

	.boot : {
		/* 
		   GRUB expects the ELF header to be near the beginning
		   of the image. 
		*/
		*(.multiboot_header)
	}

	.text : {
		*(.text)
	}
}