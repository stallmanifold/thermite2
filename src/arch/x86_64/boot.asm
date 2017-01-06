%define TRUE  1
%define FALSE 0
; VGA Buffer address.
%define VGA_BUFFER 0xb8000
; Multiboot magic number to be written to eax on start.             
%define MULTIBOOT_MAGIC 0x36d76289 


global start

section .data
str_in_pmode:     db "In Protected Mode.", 0
str_not_in_pmode: db "Not In Protected Mode.", 0
str_an_err:       db "An Error Occurred.\n", 0
str_ok:           db "OK", 0


section .text
bits 32
start:
    mov esp, stack_top

    push eax
    call check_protected_mode
    pop eax

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; Print `OK` to screen.
    mov ebx, str_ok
    call vga_print_string
    hlt

check_protected_mode:
    push ebx
    call cpu_in_protected_mode
    cmp eax, TRUE
    je .ok
    cmp eax, FALSE
    je .not_ok
    jmp .error
.ok:
    mov ebx, str_in_pmode
    jmp .done
.not_ok:
    mov ebx, str_not_in_pmode
    jmp .done
.error:
    mov ebx, str_an_err
    jmp .done
.done:
    call vga_print_string
    pop ebx
    ret

; Detect that the intel CPU is in protected mode. 
cpu_in_protected_mode:
    push ebx
    mov ebx, cr0
    and ebx, 0x01            ;
    cmp ebx, 0x01            ; Check That the PE mode flag is set in CR0.
    jne .not_protected_mode
    mov eax, TRUE
    jmp .done
.not_protected_mode:
    mov eax, FALSE
.done:
    pop ebx
    ret

check_multiboot:
    cmp eax, MULTIBOOT_MAGIC
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error


check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error


check_long_mode:
    ; test if extended processor info in available
    mov eax, 0x80000000    ; implicit argument for cpuid
    cpuid                  ; get highest supported argument
    cmp eax, 0x80000001    ; it needs to be at least 0x80000001
    jb .no_long_mode       ; if it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001    ; argument for extended processor info
    cpuid                  ; returns various feature bits in ecx and edx
    test edx, 1 << 29      ; test if the LM-bit is set in the D-register
    jz .no_long_mode       ; If it's not set, there is no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error


; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [VGA_BUFFER], 0x4f524f45
    mov dword [VGA_BUFFER+0x04], 0x4f3a4f52
    mov dword [VGA_BUFFER+0x08], 0x4f204f20
    mov byte  [VGA_BUFFER+0x0a], al
    hlt


vga_clear_buffer:
    

; Print a string to the VGA Buffer.
vga_print_string:
    mov ecx, VGA_BUFFER
    ; Memory location of string is assumed to be in ebx
    mov ah, 0x2f
.loop:
    mov al, [ebx]
    cmp al, 0x00     ; Check whether we are at the null terminator.
    je .done
    mov [ecx], ax
    add ecx, 2
    inc ebx
    jmp .loop
.done:
    ret


section .bss
align 4096
stack_bottom:
    resb 64
stack_top: