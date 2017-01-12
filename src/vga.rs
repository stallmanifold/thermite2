#![allow(dead_code)]
use core::ptr::Unique;
use core::fmt;
use arch::vga;
use spin::Mutex;


pub static GLOBAL_VGA_WRITER: Mutex<Writer> = Mutex::new(Writer {
    current: CursorPosition { row: 0, column: 0 },
    color_code: vga::ColorCode::new(vga::Color::LightGreen, vga::Color::Black),
    buffer: unsafe { Unique::new(vga::BUFFER_ADDRESS as *mut _) },
});

#[macro_use]
macro_rules! vga_println {
    ($fmt:expr) => (vga_print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => (vga_print!(concat!($fmt, "\n"), $($arg)*));
}

#[macro_use]
macro_rules! vga_print {
    ($($arg:tt)*) => ({
        $crate::vga::print(format_args!($($arg)*));
    });
}

struct CursorPosition {
    row: usize,
    column: usize,
}

pub struct Writer {
    current: CursorPosition,
    color_code: vga::ColorCode,
    buffer: Unique<vga::Buffer>,
}

impl Writer {
    fn new(buffer: Unique<vga::Buffer>, foreground: vga::Color, background: vga::Color) -> Writer {
        Writer {
            current: CursorPosition { row: 0, column: 0 },
            color_code: vga::ColorCode::new(foreground, background),
            buffer: buffer
        }
    }

    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            byte => {
                if self.current.column >= vga::BUFFER_WIDTH {
                    self.new_line();
                }
                
                if self.current.row >= vga::BUFFER_HEIGHT {
                    self.new_line();
                    self.current.row = vga::BUFFER_HEIGHT - 1;
                }
                
                let row = self.current.row;
                let col = self.current.column;
                let color_code = self.color_code;
                self.buffer().chars[row][col]
                             .set(vga::ScreenChar::new(byte, color_code));
                self.current.column += 1;
            }
        }
    }

    fn buffer(&mut self) -> &mut vga::Buffer {
        unsafe { 
            self.buffer.get_mut() 
        }
    }

    #[inline]
    fn new_line(&mut self) {
        if self.current.row >= vga::BUFFER_HEIGHT {
            // Scroll up one row.
            self.scroll_one_row();
        } else {
            self.current.row += 1;
            self.current.column = 0;
        }

    }

    #[inline]
    fn scroll(&mut self, row_count: usize) {
        for row in row_count..vga::BUFFER_HEIGHT {
            for col in 0..vga::BUFFER_WIDTH {
                let buffer = self.buffer();
                let character = buffer.chars[row][col].get();
                buffer.chars[row - row_count][col].set(character);
            }
        }

        let remaining_rows = vga::BUFFER_HEIGHT - row_count;

        for row in remaining_rows..vga::BUFFER_HEIGHT {
            self.clear_row(row);
        }

        self.current.column = 0;
    }

    #[inline]
    fn scroll_one_row(&mut self) {
        self.scroll(1);
    }

    #[inline]
    fn clear_row(&mut self, row: usize) {
        let blank = vga::ScreenChar::new(b' ', self.color_code);

        for col in 0..vga::BUFFER_WIDTH {
            self.buffer().chars[row][col].set(blank);
        }
    }

    pub fn reset_buffer(&mut self) {
        for row in 0..vga::BUFFER_HEIGHT {
            self.clear_row(row);
        }
        // Reset the cursor.
        self.current.row = 0;
        self.current.column = 0;
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


pub fn print(args: fmt::Arguments) {
    use core::fmt::Write;
    GLOBAL_VGA_WRITER.lock().write_fmt(args).unwrap();
}

pub fn clear_screen() {
    // The lock is released implicity.
    GLOBAL_VGA_WRITER.lock().reset_buffer();
}
