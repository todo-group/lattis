if(EXISTS "${LATTIS_RUST_FFI_DEBUG_LIB}" AND EXISTS "${LATTIS_RUST_FFI_RELEASE_LIB}")
  message(STATUS "Rust FFI already built; skipping cargo build")
  return()
endif()

message(STATUS "Rust FFI artifacts missing; running cargo build")
file(MAKE_DIRECTORY "${LATTIS_RUST_CARGO_TARGET_DIR}")
file(REMOVE_RECURSE "${LATTIS_RUST_WORKSPACE_STAGING_DIR}")
file(MAKE_DIRECTORY "${LATTIS_RUST_WORKSPACE_STAGING_DIR}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E copy "${LATTIS_RUST_MANIFEST}" "${LATTIS_RUST_WORKSPACE_STAGING_DIR}/Cargo.toml"
  RESULT_VARIABLE LATTIS_STAGE_MANIFEST_RESULT
)
if(NOT LATTIS_STAGE_MANIFEST_RESULT EQUAL 0)
  message(FATAL_ERROR "failed to stage Rust workspace manifest into build directory")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E copy_directory "${LATTIS_RUST_ROOT_DIR}/rust" "${LATTIS_RUST_WORKSPACE_STAGING_DIR}/rust"
  RESULT_VARIABLE LATTIS_STAGE_RUST_RESULT
)
if(NOT LATTIS_STAGE_RUST_RESULT EQUAL 0)
  message(FATAL_ERROR "failed to stage Rust workspace sources into build directory")
endif()
set(LATTIS_STAGED_MANIFEST "${LATTIS_RUST_WORKSPACE_STAGING_DIR}/Cargo.toml")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "CARGO_TARGET_DIR=${LATTIS_RUST_CARGO_TARGET_DIR}" "${LATTIS_CARGO_EXECUTABLE}" build --manifest-path "${LATTIS_STAGED_MANIFEST}" -p lattis-ffi
  WORKING_DIRECTORY "${LATTIS_RUST_WORKSPACE_STAGING_DIR}"
  RESULT_VARIABLE LATTIS_CARGO_DEBUG_RESULT
)
if(NOT LATTIS_CARGO_DEBUG_RESULT EQUAL 0)
  message(FATAL_ERROR "cargo build failed for lattis-ffi (debug)")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "CARGO_TARGET_DIR=${LATTIS_RUST_CARGO_TARGET_DIR}" "${LATTIS_CARGO_EXECUTABLE}" build --release --manifest-path "${LATTIS_STAGED_MANIFEST}" -p lattis-ffi
  WORKING_DIRECTORY "${LATTIS_RUST_WORKSPACE_STAGING_DIR}"
  RESULT_VARIABLE LATTIS_CARGO_RELEASE_RESULT
)
if(NOT LATTIS_CARGO_RELEASE_RESULT EQUAL 0)
  message(FATAL_ERROR "cargo build failed for lattis-ffi (release)")
endif()
