ENTRY(start)

SECTIONS {
	. = 1M;

	.boot : {
		/* multiboot header must be at the beginning */
		KEEP(*(.multiboot_header))
	}

	.text : {
		*(.text)
	}
}
