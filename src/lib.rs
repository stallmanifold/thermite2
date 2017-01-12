#![feature(lang_items)]
#![feature(unique, const_fn)]
#![no_std]
extern crate rlibc;
extern crate volatile;
extern crate spin;

pub mod arch;

#[macro_use]
mod vga_buffer;

// TODO: Expand the stack and add a guard page between the stack and the page tables.

#[no_mangle]
pub extern "C" fn rust_main() {
    vga_buffer::clear_screen();
    vga_println!("Hello World{}", "!");
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
