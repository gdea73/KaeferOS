%define vgabuf 0xb8000

global long_mode_start

section .text
bits 64
long_mode_start:
	; nullify data segment registers
	; to remove traces of 32-bit GDT
	mov ax, 0
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; print 'OK! ' to screen
	mov rax, 0x2F202F212F4B2F4F
	mov qword [vgabuf], rax
	hlt
