ENTRY(start)

SECTIONS {
	. = 1M;

	.boot : {
		/* multiboot header must be at the beginning */
		*(.multiboot_header)
	}

	.text : {
		*(.text)
	}
}
