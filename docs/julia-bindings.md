# Julia bindings design (proposed)

## Goal

Provide first-class Julia bindings for `lattis` that are:

* **Stable** against Rust internal refactors
* **Fast** for large lattices/graphs
* **Julian** in API ergonomics
* **Maintainable** with minimal duplicate logic

## Current architecture and design baseline

The repository already follows a layered architecture:

1. `rust/lattis` (core data model + algorithms + XML)
2. `rust/lattis-ffi` (C ABI layer)
3. `cxx/lattis` (C++ wrapper over C ABI)
4. `rust/lattis-python` (PyO3 bindings directly over Rust core)

For Julia, we should **reuse the existing C ABI boundary** and avoid introducing a second ad-hoc ABI.

## Recommended binding strategy

### 1) Use `rust/lattis-ffi` as the Julia ABI boundary

Bind Julia to a shared library exposing a C ABI (`extern "C"`) and opaque handles.

Rationale:

* ABI is explicit and language-agnostic.
* Keeps Rust internals private.
* Aligns with existing C++ bridge.
* Enables consistency tests across C++, Python, and Julia.

### 2) Add a dedicated Julia package layout

Create `julia/Lattis.jl` package (or separate repo later) with:

* `Project.toml`
* `src/Lattis.jl`
* `src/wrap_ffi.jl` (low-level `ccall` layer)
* `src/types.jl` (high-level Julia structs)
* `test/runtests.jl`

Initial recommendation: keep package in-repo during bring-up for synchronized CI and versioning.

### 3) Two-layer Julia API

#### Low-level layer (`wrap_ffi.jl`)

Responsibilities:

* direct `ccall` declarations
* pointer/handle lifetime operations
* error retrieval (`last_error` style)
* zero-copy/owned-copy boundary decisions

No user-facing abstractions here.

#### High-level layer (`types.jl`)

Responsibilities:

* expose `Basis`, `Unitcell`, `Graph`
* Julian naming and iteration patterns
* conversion to `Vector`, `Matrix`, and tuples
* exceptions instead of error codes

### 4) Memory management model

Use opaque pointers and explicit destructors in FFI:

* `lattis_graph_new...` -> `Ptr{Cvoid}` handle
* `lattis_graph_free` -> releases resource

In Julia high-level objects:

* store handle in immutable wrapper with mutable internal ref, or mutable struct
* register `finalizer` calling corresponding `_free`
* provide `close(::Graph)` for deterministic teardown

Rule: finalizers are safety nets; public API should support explicit release for heavy workflows.

### 5) Error-handling contract

FFI returns status codes (`0` success, non-zero failure). On failure:

1. Query thread-local/last error message from FFI.
2. Convert to Julia exception (`ErrorException` or custom `LattisError`).

Helper pattern:

* `check(code::Cint)` throws on non-zero
* all high-level constructors/methods call `check`

### 6) Data exchange conventions

For performance and clarity:

* **Scalars**: pass by value
* **Small fixed tuples** (e.g., coordinates): return via out-params or flat buffers
* **Bulk arrays**: two-phase API
  1. query length/count
  2. fill caller-allocated Julia `Vector{T}` via `ccall`

For matrices exposed to Julia:

* FFI can fill row-major flat buffers.
* Julia wrapper reshapes and transposes only when required, documenting cost.

### 7) API mapping guidelines (Rust/C++ -> Julia)

| Concept | Rust/C++ style | Julia style |
|---|---|---|
| Count getters | `num_sites()` | `num_sites(g)` or `nv(g)` alias |
| Coordinate tables | method returning array | `coordinates(g)::Matrix{Float64}` |
| Optional values | `Option`/nullable | `Union{T,Nothing}` |
| Iteration | index loops | `Base.iterate` support where practical |

Prefer non-mutating functions by default; provide `!` variants only when mutation is real.

### 8) Build/distribution model

Recommended phases:

1. **Dev phase**: build `rust/lattis-ffi` via Cargo/CMake, set `LIBLATTIS_PATH` for Julia tests.
2. **Packaging phase**: use `Artifacts.toml` + JLL (BinaryBuilder) for prebuilt binaries.

This separation allows immediate development without blocking on cross-platform binary infra.

### 9) Testing strategy

#### A. Contract tests at FFI boundary

Add tests near `rust/lattis-ffi` for:

* constructor/destructor symmetry
* error propagation
* buffer size validation

#### B. Julia unit tests

`test/runtests.jl` covers:

* constructors (`basis`, `unitcell`, `graph`)
* coordinate/bond extraction
* XML read/write smoke tests
* exception paths

#### C. Cross-language parity tests

Use identical fixtures and verify parity among Rust, C++, Python, Julia for:

* site count
* bond count
* representative coordinates

## Minimum viable Julia API (v0)

```julia
using Lattis

b = Basis([1.0 0.0; 0.0 1.0])
u = Unitcell(b)
add_site!(u, [0.0, 0.0])
add_site!(u, [0.5, 0.5])
add_bond!(u, 1, 2, [0, 0])

g = Graph(u, [4, 4], [:periodic, :periodic])

n = num_sites(g)
xy = coordinates(g)
```

Notes:

* indices in Julia should be **1-based** even if internal FFI uses 0-based.
* wrapper performs index translation and bounds checks.

## Proposed implementation roadmap

1. Extend `rust/lattis-ffi` with missing primitives required by Julia (`counts`, `fill buffers`, constructors).
2. Create in-repo `julia/Lattis.jl` skeleton and low-level `ccall` wrappers.
3. Implement high-level `Basis`, `Unitcell`, `Graph` wrappers + finalizers.
4. Add tests and CI job (`julia --project -e 'using Pkg; Pkg.test()'`).
5. Add docs/examples parallel to Python example coverage.
6. Stabilize and tag first Julia-compatible release.

## Non-goals for initial release

* Full feature parity with all Rust internals.
* Zero-copy for every bulk API (optimize later based on profiling).
* Custom Julia macros/DSL for lattice definition.

## Risk notes and mitigations

* **ABI drift risk**: mitigate by versioned FFI header + CI ABI checks.
* **Lifetime bugs**: mitigate with strict ownership tables and destructor tests.
* **Performance regressions**: mitigate with benchmark fixtures for large graphs.

## Summary

Adopt Julia bindings through the existing Rust C ABI (`rust/lattis-ffi`), implement a two-layer Julia package (`ccall` low-level + Julian high-level API), and prioritize correctness/lifetime guarantees first, then optimize data movement and packaging.
