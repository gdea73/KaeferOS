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

	; call rust main
	extern rust_main
	call rust_main

	; print 'OK!' to screen
	mov rax, 0x8F20A721A74BA74F
	mov qword [vgabuf], rax
	mov rax, 0x8F208F208F208F20
	mov qword [vgabuf + 0x08], rax
	mov rax, 0x8F208F208F208F20
	mov qword [vgabuf + 0x10], rax
	mov rax, 0x8F208F208F208F20
	mov qword [vgabuf + 0x18], rax
	mov rax, 0x8F208F208F208F20
	mov qword [vgabuf + 0x20], rax
	hlt
