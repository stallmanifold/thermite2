pub use self::imp::{
	vga,
};

/// Thermite Kernel 
///
/// x86_64 architecture-specific support
#[cfg(target_arch = "x86_64")]
#[path="x86_64"]
#[doc(hidden)]
mod imp {
	pub mod vga;
}
