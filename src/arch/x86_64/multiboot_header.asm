%define MAGIC 0xe85250d6
; multiboot 2 magic number

section .multiboot_header
header_start:
	dd MAGIC
	dd 0							; i386 protected mode
	dd header_end - header_start	; header length
	; checksum
	dd 0x100000000 - (MAGIC + 0 + (header_end - header_start))

	; end tag
	dw 0	; type
	dw 0	; flags
	dd 8	; size
header_end:
