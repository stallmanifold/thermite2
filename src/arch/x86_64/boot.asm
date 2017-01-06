global start

section .text
bits 32
start:
    call check_protected_mode
    cmp eax, 0x01
    je .ok
    cmp eax, 0x00
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
    mov eax, 0x01
    ret
.not_protected_mode:
    mov eax, 0x00
    ret

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error