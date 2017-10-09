%define vgabuf(offset) 0xB8000 + offset
%define multi_magic 0x36D76289

global start

section .text
bits 32
start:
	mov esp, stack_top

	call check_multiboot
	call check_cpuid

	; print 'OK! ' to screen
	mov dword [vgabuf(0x00)], 0x2F4B2F4F
	mov dword [vgabuf(0x04)], 0x0F202F21
	hlt

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
stack_bottom:
	resb 64		; reserve 64 bytes (uninitialized) for the stack
stack_top:
