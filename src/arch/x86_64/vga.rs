use volatile::VolatileCell;

pub const BUFFER_HEIGHT: usize = 25;
pub const BUFFER_WIDTH: usize = 80;
pub const BUFFER_ADDRESS: usize = 0xB8000;


#[derive(Debug, Clone, Copy)]
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
pub struct ColorCode(u8);

impl ColorCode {
    #[inline]
    pub const fn new(foreground: Color, background: Color) -> ColorCode {
        ColorCode((background as u8) << 4 | (foreground as u8))
    }
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct ScreenChar {
    ascii_character: u8,
    color_code: ColorCode,
}

impl ScreenChar {
	#[inline]
	pub const fn new(ascii_character: u8, color_code: ColorCode) -> ScreenChar {
		ScreenChar {
			ascii_character: ascii_character,
			color_code: color_code,
		}
	}
}

pub struct Buffer {
    pub chars: [[VolatileCell<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT],
}
