use lattis_ffi::{
    lattis_basis_from_xml, lattis_basis_raw_free, lattis_last_error_message, lattis_string_free,
};
use std::ffi::{CStr, CString};
use std::ptr;

#[test]
fn reports_error_message_after_failure() {
    let xml = CString::new("<LATTICES><LATTICE name=\"ok\" dimension=\"1\"><BASIS><VECTOR>1</VECTOR></BASIS></LATTICE></LATTICES>").unwrap();
    let missing_name = CString::new("missing").unwrap();

    let basis_ptr = lattis_basis_from_xml(xml.as_ptr(), missing_name.as_ptr());
    assert!(basis_ptr.is_null());

    let message_ptr = lattis_last_error_message();
    assert!(!message_ptr.is_null());

    let message = unsafe { CStr::from_ptr(message_ptr).to_string_lossy().into_owned() };
    assert!(message.contains("lattis_basis_from_xml"));

    lattis_string_free(message_ptr);
}

#[test]
fn clears_error_message_after_success() {
    let xml = CString::new("<LATTICES><LATTICE name=\"ok\" dimension=\"1\"><BASIS><VECTOR>1</VECTOR></BASIS></LATTICE></LATTICES>").unwrap();
    let missing_name = CString::new("missing").unwrap();
    let ok_name = CString::new("ok").unwrap();

    let failed = lattis_basis_from_xml(xml.as_ptr(), missing_name.as_ptr());
    assert!(failed.is_null());

    let ok_ptr = lattis_basis_from_xml(xml.as_ptr(), ok_name.as_ptr());
    assert!(!ok_ptr.is_null());

    lattis_basis_raw_free(ok_ptr);

    let message_ptr = lattis_last_error_message();
    assert_eq!(message_ptr, ptr::null_mut());
}
