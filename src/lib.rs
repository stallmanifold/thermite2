#![feature(lang_items)]
#![feature(unique, const_fn)]
#![no_std]
extern crate rlibc;
extern crate volatile;
extern crate spin;
extern crate multiboot2;

pub mod arch;

#[macro_use]
mod vga;

// TODO: Expand the stack and add a guard page between the stack and the page tables.

#[no_mangle]
pub extern "C" fn rust_main(multiboot_information_address: usize) {
    vga::clear_screen();
    let boot_info = unsafe { multiboot2::load(multiboot_information_address) };
    let memory_map = boot_info.memory_map()
                              .expect("Memory map tag required.");
    vga_println!("Available memory areas:");
    for region in memory_map.memory_regions() {
        vga_println!("    start: 0x{:x}, length: 0x{:x}",
            region.base_address(), region.length());
    }

    let elf_sections = boot_info.elf_sections()
                                .expect("Elf-sections are required.");

    let string_table = elf_sections.string_table();                            
    vga_println!("Kernel sections:");
    /*
    for (i, section) in elf_sections.elf_sections().enumerate() {
        vga_println!("{};    type: 0x{:X}; address: 0x{:X}; size: 0x{:X}; flags: 0x{:X}",
            i, section.section_type(), section.section_start_address(), section.size_bytes(), section.flags());
    }
    */
    for (i, section) in elf_sections.elf_sections().enumerate() {
        vga_println!("{}; name: {};", i, string_table.section_name(section));
    }
    
    loop {}
}

#[lang = "eh_personality"] 
extern fn eh_personality() {}

#[lang = "panic_fmt"] 
#[no_mangle] 
pub extern fn panic_fmt(fmt: core::fmt::Arguments, 
                        file: &'static str,
                        line: u32) -> ! 
{
    vga_println!("\n\nKernel PANIC in file {} at line {}", file, line);
    vga_println!("    {}", fmt);
    
    loop{}
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
	loop {}
}
