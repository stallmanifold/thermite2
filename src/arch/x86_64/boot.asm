%define TRUE  1
%define FALSE 0
%define VGA_BUFFER 0xb8000    ; VGA Buffer address.

global start

section .data
str_ok:     db "In Protected Mode.", 0
str_not_ok: db "Not In Protected Mode.", 0
str_err:    db "An Error Occurred.", 0

section .text
bits 32
start:
    mov esp, stack_top
    call check_protected_mode
    hlt

check_protected_mode:
    call cpu_in_protected_mode
    cmp eax, TRUE
    je .ok
    cmp eax, FALSE
    je .not_ok
    jmp .error
.ok:
    mov ebx, str_ok
    jmp .done
.not_ok:
    mov ebx, str_not_ok
    jmp .done
.error:
    mov ebx, str_err
    jmp .done
.done:
    call vga_print_string
    ret

; Detect that the intel CPU is in protected mode. 
cpu_in_protected_mode:
    mov eax, cr0
    and eax, 0x01            ;
    cmp eax, 0x01            ; Check That the PE mode flag is set in CR0.
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


; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [VGA_BUFFER], 0x4f524f45
    mov dword [VGA_BUFFER+0x04], 0x4f3a4f52
    mov dword [VGA_BUFFER+0x08], 0x4f204f20
    mov byte  [VGA_BUFFER+0x0a], al
    hlt


section .bss
align 4096
stack_bottom:
    resb 64
stack_top: