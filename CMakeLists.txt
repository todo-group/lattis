cmake_minimum_required(VERSION 3.14)
include(cmake/prefix.cmake)

file(READ "${CMAKE_CURRENT_LIST_DIR}/Cargo.toml" LATTIS_WORKSPACE_MANIFEST)
string(REGEX MATCH "\\[workspace\\.package\\][^\[]*version[ \t]*=[ \t]*\"([^\"]+)\"" _lattis_version_match "${LATTIS_WORKSPACE_MANIFEST}")
if(NOT CMAKE_MATCH_1)
  message(FATAL_ERROR "Could not read lattis version from root Cargo.toml [workspace.package]")
endif()
set(LATTIS_WORKSPACE_VERSION "${CMAKE_MATCH_1}")

project(lattis VERSION ${LATTIS_WORKSPACE_VERSION} LANGUAGES CXX)
include(cmake/postfix.cmake)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(FetchContent)

set(LATTIS_PKG_VERSION ${PROJECT_VERSION})
set(LATTIS_INSTALL_CMAKEDIR ${CMAKE_INSTALL_LIBDIR}/cmake/lattis)
option(LATTIS_BUILD_TESTS "Build C++ tests" OFF)

add_library(lattis INTERFACE)
target_include_directories(lattis INTERFACE ${PROJECT_SOURCE_DIR}/cxx)

set(LATTIS_RUST_FFI_RELEASE_LIB
  ${CMAKE_BINARY_DIR}/rust-target/release/${CMAKE_SHARED_LIBRARY_PREFIX}lattis_ffi${CMAKE_SHARED_LIBRARY_SUFFIX}
)
set(LATTIS_RUST_FFI_DEBUG_LIB
  ${CMAKE_BINARY_DIR}/rust-target/debug/${CMAKE_SHARED_LIBRARY_PREFIX}lattis_ffi${CMAKE_SHARED_LIBRARY_SUFFIX}
)
set(LATTIS_RUST_CARGO_TARGET_DIR ${CMAKE_BINARY_DIR}/rust-target)
set(LATTIS_RUST_WORKSPACE_STAGING_DIR ${CMAKE_BINARY_DIR}/rust-workspace)

find_program(LATTIS_CARGO_EXECUTABLE cargo)

if(LATTIS_CARGO_EXECUTABLE)
  add_custom_target(lattis_rust_ffi_build
    COMMAND ${CMAKE_COMMAND}
      -DLATTIS_CARGO_EXECUTABLE=${LATTIS_CARGO_EXECUTABLE}
      -DLATTIS_RUST_FFI_DEBUG_LIB=${LATTIS_RUST_FFI_DEBUG_LIB}
      -DLATTIS_RUST_FFI_RELEASE_LIB=${LATTIS_RUST_FFI_RELEASE_LIB}
      -DLATTIS_RUST_WORK_DIR=${PROJECT_SOURCE_DIR}/rust
      -DLATTIS_RUST_ROOT_DIR=${PROJECT_SOURCE_DIR}
      -DLATTIS_RUST_MANIFEST=${PROJECT_SOURCE_DIR}/Cargo.toml
      -DLATTIS_RUST_CARGO_TARGET_DIR=${LATTIS_RUST_CARGO_TARGET_DIR}
      -DLATTIS_RUST_WORKSPACE_STAGING_DIR=${LATTIS_RUST_WORKSPACE_STAGING_DIR}
      -P ${PROJECT_SOURCE_DIR}/cmake/build_rust_ffi_if_needed.cmake
    COMMENT "Ensuring Rust FFI library exists"
  )
elseif(NOT EXISTS ${LATTIS_RUST_FFI_RELEASE_LIB} AND NOT EXISTS ${LATTIS_RUST_FFI_DEBUG_LIB})
  message(FATAL_ERROR
    "Rust XML backend requires rust/lattis-ffi and cargo is not available in PATH. Install cargo or prebuild rust/lattis-ffi."
  )
endif()

add_library(lattis_rust_ffi SHARED IMPORTED GLOBAL)
set_target_properties(lattis_rust_ffi PROPERTIES
  IMPORTED_LOCATION ${LATTIS_RUST_FFI_DEBUG_LIB}
  IMPORTED_LOCATION_DEBUG ${LATTIS_RUST_FFI_DEBUG_LIB}
  IMPORTED_LOCATION_RELEASE ${LATTIS_RUST_FFI_RELEASE_LIB}
  IMPORTED_LOCATION_RELWITHDEBINFO ${LATTIS_RUST_FFI_RELEASE_LIB}
  IMPORTED_LOCATION_MINSIZEREL ${LATTIS_RUST_FFI_RELEASE_LIB}
)
if(TARGET lattis_rust_ffi_build)
  add_dependencies(lattis_rust_ffi lattis_rust_ffi_build)
endif()
target_link_libraries(lattis INTERFACE lattis_rust_ffi)

include(eigen3)
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME AND LATTIS_BUILD_TESTS)
  include(googletest)
endif()
FetchContent_MakeAvailable(${FetchContents})

if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
  if(LATTIS_BUILD_TESTS)
    add_subdirectory(cxx/test test)
  endif()
  add_subdirectory(cxx/example example)
endif()

if(LATTIS_CARGO_EXECUTABLE)
  configure_file(
    ${PROJECT_SOURCE_DIR}/cmake/install_ensure_rust_ffi.cmake.in
    ${CMAKE_BINARY_DIR}/install_ensure_rust_ffi.cmake
    @ONLY
  )
  install(SCRIPT ${CMAKE_BINARY_DIR}/install_ensure_rust_ffi.cmake)
endif()

configure_package_config_file(
  ${PROJECT_SOURCE_DIR}/cmake/lattisConfig.cmake.in
  ${CMAKE_BINARY_DIR}/lattisConfig.cmake
  INSTALL_DESTINATION ${LATTIS_INSTALL_CMAKEDIR}
  PATH_VARS CMAKE_INSTALL_INCLUDEDIR CMAKE_INSTALL_LIBDIR
)

write_basic_package_version_file(
  ${CMAKE_BINARY_DIR}/lattisConfigVersion.cmake
  VERSION ${LATTIS_PKG_VERSION}
  COMPATIBILITY SameMajorVersion
)

configure_file(
  ${PROJECT_SOURCE_DIR}/cmake/lattis.pc.in
  ${CMAKE_BINARY_DIR}/lattis.pc
  @ONLY
)

install(DIRECTORY ${PROJECT_SOURCE_DIR}/cxx/lattis/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/lattis
  FILES_MATCHING
  PATTERN "*.hpp"
  PATTERN "*.h"
)

install(FILES
  $<$<CONFIG:Debug>:${LATTIS_RUST_FFI_DEBUG_LIB}>
  $<$<NOT:$<CONFIG:Debug>>:${LATTIS_RUST_FFI_RELEASE_LIB}>
  DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES ${PROJECT_SOURCE_DIR}/LICENSE-2.0.txt
  DESTINATION ${CMAKE_INSTALL_DATADIR}/lattis
)

install(FILES
  ${CMAKE_BINARY_DIR}/lattisConfig.cmake
  ${CMAKE_BINARY_DIR}/lattisConfigVersion.cmake
  DESTINATION ${LATTIS_INSTALL_CMAKEDIR}
)

install(FILES
  ${CMAKE_BINARY_DIR}/lattis.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)
