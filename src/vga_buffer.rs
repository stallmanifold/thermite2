#![allow(dead_code)]
use core::ptr::Unique;
use core::fmt;
use arch::vga;
use spin::Mutex;


pub static GLOBAL_VGA_WRITER: Mutex<Writer> = Mutex::new(Writer {
    column_position: 0,
    color_code: vga::ColorCode::new(vga::Color::LightGreen, vga::Color::Black),
    buffer: unsafe { Unique::new(vga::BUFFER_ADDRESS as *mut _) },
});

macro_rules! vga_println {
    ($fmt:expr) => (vga_print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => (vga_print!(concat!($fmt, "\n"), $($arg)*));
}

macro_rules! vga_print {
    ($($arg:tt)*) => ({
        $crate::vga_buffer::print(format_args!($($arg)*));
    });
}

pub fn print(args: fmt::Arguments) {
    use core::fmt::Write;
    GLOBAL_VGA_WRITER.lock().write_fmt(args).unwrap();
}

pub struct Writer {
    column_position: usize,
    color_code: vga::ColorCode,
    buffer: Unique<vga::Buffer>,
}

impl Writer {
    fn new(buffer: Unique<vga::Buffer>, foreground: vga::Color, background: vga::Color) -> Writer {
        Writer {
            column_position: 0,
            color_code: vga::ColorCode::new(foreground, background),
            buffer: buffer
        }
    }

    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            byte => {
                if self.column_position >= vga::BUFFER_WIDTH {
                    self.new_line();
                }

                let row = vga::BUFFER_HEIGHT - 1;
                let col = self.column_position;

                let color_code = self.color_code;
                self.buffer().chars[row][col]
                             .set(vga::ScreenChar::new(byte, color_code));
                self.column_position += 1;
            }
        }
    }

    fn buffer(&mut self) -> &mut vga::Buffer {
        unsafe { 
            self.buffer.get_mut() 
        }
    }

    fn new_line(&mut self) {
        for row in 1..vga::BUFFER_HEIGHT {
            for col in 0..vga::BUFFER_WIDTH {
                let buffer = self.buffer();
                let character = buffer.chars[row][col].get();
                buffer.chars[row - 1][col].set(character);
            }
        }
        self.clear_row(vga::BUFFER_HEIGHT-1);
        self.column_position = 0;
    }

    fn clear_row(&mut self, row: usize) {
        let blank = vga::ScreenChar::new(b' ', self.color_code);

        for col in 0..vga::BUFFER_WIDTH {
            self.buffer().chars[row][col].set(blank);
        }
    }

}

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for byte in s.bytes() {
          self.write_byte(byte);
        }
        Ok(())
    }
}

pub fn clear_screen() {
    for _ in 0..vga::BUFFER_HEIGHT {
        vga_println!("");
    }
}
