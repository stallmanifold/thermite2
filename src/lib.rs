#![feature(lang_items)]
#![feature(unique, const_fn)]
#![no_std]
extern crate rlibc;
extern crate volatile;
extern crate spin;

mod vga_buffer;

//use core::fmt::Write;
//use core::ptr::Unique;

const VGA_BUFFER_ADDRESS: usize = 0xB8000;
// TODO: Expand the stack and add a guard page between the stack and the page tables.

#[no_mangle]
pub extern "C" fn rust_main() {
    use core::fmt::Write;
    vga_buffer::WRITER.lock().write_str("Hello again");
    write!(vga_buffer::WRITER.lock(), ", some numbers: {} {}", 42, 1.337);
    loop{}
}

#[lang = "eh_personality"] 
extern fn eh_personality() {}

#[lang = "panic_fmt"] 
#[no_mangle] 
pub extern fn panic_fmt() -> ! {
    loop{}
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
	loop {}
}
