%define TRUE  1
%define FALSE 0
; VGA Buffer address.
%define VGA_BUFFER 0xb8000
; Multiboot magic number to be written to eax on start.             
%define MULTIBOOT_MAGIC 0x36d76289 


global _start
extern long_mode_start

section .data
str_in_pmode:     db "In Protected Mode.", 0
str_not_in_pmode: db "Not In Protected Mode.", 0
str_an_err:       db "An Error Occurred.\n", 0
str_ok:           db "OK", 0


section .text
bits 32
_start:
    mov esp, stack_top
    mov edi, ebx        ; Move multiboot info pointer

    push eax
    call check_protected_mode
    pop eax

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call initialize_page_tables
    call enable_paging

    ; Load the 64-bit global descriptor table
    lgdt [gdt64.pointer]

    ; Update selectors
    mov ax, gdt64.data_seg
    mov ss, ax   ; Stack Selector
    mov ds, ax   ; Data Selector
    mov es, ax   ; Extra Selector

    call enable_SSE

    jmp gdt64.code_seg:long_mode_start

    ; Print `OK` to screen
    mov ebx, str_ok
    call vga_print_string
    hlt


check_protected_mode:
    push ebx
    call detect_protected_mode
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
detect_protected_mode:
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
    push ecx

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
    pop ecx
    ret
.no_cpuid:
    pop ecx
    mov al, "1"
    jmp error


check_long_mode:
    push edx
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
    pop edx
    ret
.no_long_mode:
    mov al, "2"
    pop edx
    jmp error


; Initial initialization of kernel memory space. We must identity map
; the lower 4GB of the processor's address space initially before we transition to
; 64-bit mode.
initialize_page_tables:
    ; Map the first PML4E entry to the PDPTE table.
    ; This is called the P4 table in the bss section.
    mov eax, p3_table
    or eax, 0b11         ; Present + Writable
    mov [p4_table], eax

    ; Map the first PDPTE entry to the first PDE table.
    ; The first PDPTE table is called P3 and the first PDE table
    ; is called P2 in the .bss section.
    mov eax, p2_table
    or eax, 0b11         ; Present + Writable
    mov [p3_table], eax

    ; Map each P2 entry to a huge 2MiB page.
    mov ecx, 0           ; Initialize counter

.map_p2_table:
    ; For each P2 entry (indexed by ecx), map that entry to a 2MiB page 
    ; starting at address 2MiB * [ecx].
    mov eax, 0x200000             ; 2MiB
    mul ecx                       ; Starting address of page number [ecx]
    or eax, 0b10000011            ; Present + Writable + PS
    mov [p2_table + ecx * 8], eax ; Map page entry [ecx]
    inc ecx            
    cmp ecx, 512                  ; If counter == 512, the whole P2 table is mapped
    jne .map_p2_table        

    ret


enable_paging:
    ; Load P4 table address to CR3 register. The CR3 register is used to access
    ; the page tables.
    mov eax, p4_table
    mov cr3, eax

    ; Enable the PAE flag in register CR4 (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging in the CR0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret


; Check for SSE and enable it. If it's not supported throw error "a".
enable_SSE:
    ; check for SSE
    mov eax, 0x1
    cpuid
    test edx, 1<<25
    jz .no_SSE

    ; Enable SSE
    mov eax, cr0
    and ax, 0xFFFB      ; Clear coprocessor emulation CR0.EM
    or ax, 0x2          ; Set coprocessor monitoring  CR0.MP
    mov cr0, eax
    mov eax, cr4
    or ax, 3 << 9       ; Set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
    mov cr4, eax

    ret
.no_SSE:
    mov al, "a"
    jmp error


; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [VGA_BUFFER], 0x4f524f45
    mov dword [VGA_BUFFER+0x04], 0x4f3a4f52
    mov dword [VGA_BUFFER+0x08], 0x4f204f20
    mov byte  [VGA_BUFFER+0x0a], al
    hlt
    

; Print a string to the VGA Buffer.
vga_print_string:
    push ebp
    
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
    pop ebp
    ret


section .rodata
gdt64:
    dq 0 ; Zero entry
.code_seg: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53) ; Code segment
.data_seg: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) ; Data segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64


section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 4096
stack_top:
