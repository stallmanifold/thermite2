section .multiboot_header
header_start:
    dd 0xe85250d6                ; magic number
    dd 0                         ; architecture (0 for protected mode i386, 4 for MIPS)
    dd header_end - header_start ; header length
    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    ; The additional multiboot tags are optional. See section 3.1.1 of the
    ; multiboot specification.

    ; end tag
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
header_end: