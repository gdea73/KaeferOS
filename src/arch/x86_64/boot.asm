%define vgabuf(offset) 0xB8000 + offset
%define multi_magic 0x36D76289

global start

section .text
bits 32
start:
	mov esp, stack_top

	call check_multiboot
	call check_cpuid
	call check_long_mode

	call init_page_tables
	call enable_paging

	; print 'OK! ' to screen
	mov dword [vgabuf(0x00)], 0x2F4B2F4F
	mov dword [vgabuf(0x04)], 0x0F202F21
	hlt

init_page_tables:
	; map the first entry in P4 to the P3 table
	mov eax, p3_table
	or eax, 0b11	; set present & writable flags
	mov [p4_table], eax

	; map the first P3 entry to the P2 table
	mov eax, p2_table
	or eax, 0b11
	mov [p3_table], eax

	; now, map each entry in P2 to a 'huge' 2MB page
	mov ecx, 0		; iterator

.map_p2_table:
	; map the P2 entry with offset specified in ECX to a 2MB page
	; with address 2MB*ECX
	mov eax, 0x200000	; 2 MB
	mul ecx				; start address of this page
	or eax, 0b10000011	; present, writable, and huge flags
	mov [p2_table + ecx * 8], eax
	inc ecx
	cmp ecx, 512		; if ECX == 512, the whole P2 table is mapped
	jne .map_p2_table

	ret

enable_paging:
	; load address of P4 to CR3; the CPU will read this address to locate
	; the page table once in long mode.
	mov eax, p4_table
	mov cr3, eax

	; enable Physical Address Extension flag (bit 5) in CR4
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set the long mode bit in the Model Specific Register
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; enable paging in the CR0 register
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret


check_multiboot:
	cmp eax, multi_magic
	jne .no_multiboot
	ret

.no_multiboot:
	mov al, "0" 	; set FLAGS register to zero
	jmp error

check_cpuid:
	pushfd			; push FLAGS register onto the stack
	pop eax 		; pop its contents to EAX ...
	mov ecx, eax	; ... and to ECX
	xor eax, 1 << 21; flip bit 21 of the FLAGS register (the ID bit)
	push eax
	popfd			; apply flipped bit to FLAGS from the stack

	; now, we read FLAGS again to determine whether the flip stuck
	pushfd
	pop eax

	; return FLAGS to its normal state, if changed by the flip
	push ecx
	popfd

	; compare versions of FLAGS to see if the flip stuck
	cmp eax, ecx
	je .no_cpuid
	ret

.no_cpuid:
	mov al, "1"
	jmp error

; see http://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
check_long_mode:
	mov eax, 0x80000000		; CPUID implicit arg
	cpuid					; get maximum supported parameter
	cmp eax, 0x80000001		; if maximum supported parameter is less than this,
	jb .no_long_mode		; the CPU has no knowledge of long mode.

	; use extended info to check for long mode
	mov eax, 0x80000001		; argument for extended CPU info
	cpuid					; writes feature bits to ECX and EDX
	test edx, 1 << 29		; check if LM bit is set in EDX;
	jz .no_long_mode		; if not, the CPU does not support long mode.
	ret

.no_long_mode:
	mov al, "2"
	jmp error

; prints the error code to VGA text buffer and halts
; param: ASCII error code in al
error:
	mov dword [vgabuf(0x00)], 0x4F6E4F41		; 'An' (0x4f is white text on red bg)
	mov dword [vgabuf(0x04)], 0x4F654F20		;   ' e'
	mov dword [vgabuf(0x08)], 0x4F724F72		;     'rr'
	mov dword [vgabuf(0x0C)], 0x4F724F6F		;		'or'
	mov dword [vgabuf(0x10)], 0x4F684F20		;		  ' h'
	mov dword [vgabuf(0x14)], 0x4F734F61		;			'as'
	mov dword [vgabuf(0x18)], 0x4F6F4F20		;			  ' o'
	mov dword [vgabuf(0x1C)], 0x4F634F63		;				'cc'
	mov dword [vgabuf(0x20)], 0x4F724F75		;				  'ur'
	mov dword [vgabuf(0x24)], 0x4F654F72		;				    're'
	mov dword [vgabuf(0x28)], 0x4F3A4F64		;					  'd:'
	mov word [vgabuf(0x2C)], 0x0F20
	mov byte [vgabuf(0x30)], al
	hlt

section .bss
; paging plan: 512 2-MB pages make up the first 1 GB of the kernel
; ensure page aligned page tables
align 4096
p4_table:
	resb 4096
p3_table:
	resb 4096
p2_table:
	resb 4096
stack_bottom:
	resb 64		; reserve 64 bytes (uninitialized) for the stack
stack_top:
