%define TRUE  1
%define FALSE 0

global start

section .text
bits 32
start:
    mov esp, stack_top
    call check_protected_mode
    cmp eax, TRUE
    je .ok
    cmp eax, FALSE
    je .not_ok
    jmp .error
.ok:
    ; print `OK` to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt
.not_ok:
    ; print `KO` to screen
    mov dword [0xb8000], 0x2f4f2f4b
    hlt
.error:
    ; print 'ER' to screen
    mov dword [0xb8000], 0x2f522f45
    hlt

; Detect that the intel CPU is in protected mode. 
check_protected_mode:
    mov eax, cr0
    and eax, 0x01
    cmp eax, 0x01
    jne .not_protected_mode
    mov eax, TRUE
    ret
.not_protected_mode:
    mov eax, FALSE
    ret

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error

; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt

section .bss
align 4096
stack_bottom:
    resb 64
stack_top: