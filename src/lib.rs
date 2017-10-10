#![feature(lang_items)]
#![no_std]

extern crate rlibc;

#[no_mangle]
pub extern fn rust_main() {
	// WARNING: the stack frame cannot exceed 64 bytes or page faults may occur.
	let bs = b"KaeferOS";
	let color_byte = 0xB8;

	let mut colored_text = [color_byte; 16];
	for (i, char_byte) in bs.into_iter().enumerate() {
		colored_text[i * 2] = *char_byte;
	}

	// write welcome message to the center of the VGA text buffer
	let buf = (0xB8000 + 1992) as *mut _;
	unsafe { *buf = colored_text };

	loop{}
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] #[no_mangle] pub extern fn panic_fmt() -> ! {loop{}}
