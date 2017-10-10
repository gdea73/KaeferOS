use core::ptr::Unique;
use volatile::Volatile;

#[allow(dead_code)]
#[repr(u8)]
pub enum Color {
	Black      = 0,
    Blue       = 1,
    Green      = 2,
    Cyan       = 3,
    Red        = 4,
    Magenta    = 5,
    Brown      = 6,
    LightGray  = 7,
    DarkGray   = 8,
    LightBlue  = 9,
    LightGreen = 10,
    LightCyan  = 11,
    LightRed   = 12,
    Pink       = 13,
    Yellow     = 14,
    White      = 15,
}

#[derive(Debug, Clone, Copy)]
struct ColorCode(u8);

impl ColorCode {
	const fn new(foreground: Color, background: Color) -> ColorCode {
		ColorCode((background as u8) << 4 | (foreground as u8))
	}
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
struct ScreenChar {
	ascii_character: u8,
	color_code: ColorCode,
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

struct Buffer {
	chars: [[Volatile<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT],
}

pub struct Writer {
	column_position: usize,
	color_code: ColorCode,
	buffer: Unique<Buffer>,
}

impl Writer {
	pub fn write_byte(&mut self, byte: u8) {
		match byte {
			b'\n' => self.new_line(),
			byte => {
				if self.column_position >= BUFFER_WIDTH {
					self.new_line();
				}
				let row = BUFFER_HEIGHT - 1;
				let col = self.column_position;

				let color_code = self.color_code;
				// we use write() to ensure the compiler won't optimize away
				// these writes (since we never read from Writer)
				self.buffer().chars[row][col].write(ScreenChar {
					ascii_character: byte,
					color_code: color_code,
				});
				self.column_position += 1;
			}
		}
	}

	pub fn write_str(&mut self, s: &str) {
		for byte in s.bytes() {
			self.write_byte(byte)
		}
	}

	fn buffer(&mut self) -> &mut Buffer {
		unsafe { self.buffer.as_mut() }
	}

	fn new_line(&mut self) {

	}
}

pub fn printToScreenTest() {
	// use the VGA buffer module to write to the screen
	let mut w = Writer {
		column_position: 0,
		color_code: ColorCode::new(Color::Yellow, Color::DarkGray),
		buffer: unsafe { Unique::new_unchecked(0xB8000 as *mut _) },
	};

	w.write_str("KaeferOS: the featureless operating system");
}
