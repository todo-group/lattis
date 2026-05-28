module WrapFFI

using Libdl

export liblattis_path, has_liblattis
export lattis_basis_raw, lattis_unitcell_raw, lattis_graph_raw
export checked_last_error
export basis_from_xml_raw, unitcell_from_xml_raw, graph_from_xml_raw
export basis_to_xml_raw, unitcell_to_xml_raw, graph_to_xml_raw
export free_basis_raw, free_unitcell_raw, free_graph_raw

const _DEFAULT_NAMES = (
    "liblattis_ffi.so",
    "liblattis_ffi.dylib",
    "lattis_ffi.dll",
)

# Rust #[repr(C)] mirrors
struct lattis_basis_raw
    dim::Csize_t
    values_len::Csize_t
    values::Ptr{Cdouble}
end

struct lattis_unitcell_raw
    dim::Csize_t
    num_sites::Csize_t
    site_types::Ptr{Cint}
    site_coordinates_len::Csize_t
    site_coordinates::Ptr{Cdouble}
    num_bonds::Csize_t
    bond_sources::Ptr{Csize_t}
    bond_targets::Ptr{Csize_t}
    bond_types::Ptr{Cint}
    bond_offsets_len::Csize_t
    bond_offsets::Ptr{Int64}
end

struct lattis_graph_raw
    dim::Csize_t
    num_sites::Csize_t
    site_types::Ptr{Cint}
    site_coordinates_len::Csize_t
    site_coordinates::Ptr{Cdouble}
    num_bonds::Csize_t
    bond_sources::Ptr{Csize_t}
    bond_targets::Ptr{Csize_t}
    bond_types::Ptr{Cint}
end

function liblattis_path()::Union{String,Nothing}
    if haskey(ENV, "LIBLATTIS_PATH") && !isempty(ENV["LIBLATTIS_PATH"])
        return ENV["LIBLATTIS_PATH"]
    end
    lib = Libdl.find_library(collect(_DEFAULT_NAMES))
    return isempty(lib) ? nothing : lib
end

has_liblattis()::Bool = !isnothing(liblattis_path())

function _with_lib(f::Function)
    lib = liblattis_path()
    isnothing(lib) && error("lattis-ffi library not found. Set LIBLATTIS_PATH to the built shared library path.")
    return f(lib)
end

function checked_last_error()::String
    _with_lib() do lib
        ptr = ccall((:lattis_last_error_message, lib), Ptr{Cchar}, ())
        if ptr == C_NULL
            return "unknown lattis-ffi error"
        end
        try
            return unsafe_string(ptr)
        finally
            ccall((:lattis_string_free, lib), Cvoid, (Ptr{Cchar},), ptr)
        end
    end
end

function _cstring_args(f::Function, xml::AbstractString, name::AbstractString)
    return _with_lib() do lib
        c_xml = Base.cconvert(Cstring, xml)
        c_name = Base.cconvert(Cstring, name)
        GC.@preserve c_xml c_name begin
            return f(lib, Base.unsafe_convert(Cstring, c_xml), Base.unsafe_convert(Cstring, c_name))
        end
    end
end

function basis_from_xml_raw(xml::AbstractString, name::AbstractString)::Ptr{lattis_basis_raw}
    ptr = _cstring_args(xml, name) do lib, c_xml, c_name
        ccall((:lattis_basis_from_xml, lib), Ptr{lattis_basis_raw}, (Cstring, Cstring), c_xml, c_name)
    end
    ptr == C_NULL && error(checked_last_error())
    return ptr
end

function unitcell_from_xml_raw(xml::AbstractString, name::AbstractString)::Ptr{lattis_unitcell_raw}
    ptr = _cstring_args(xml, name) do lib, c_xml, c_name
        ccall((:lattis_unitcell_from_xml, lib), Ptr{lattis_unitcell_raw}, (Cstring, Cstring), c_xml, c_name)
    end
    ptr == C_NULL && error(checked_last_error())
    return ptr
end

function graph_from_xml_raw(xml::AbstractString, name::AbstractString)::Ptr{lattis_graph_raw}
    ptr = _cstring_args(xml, name) do lib, c_xml, c_name
        ccall((:lattis_graph_from_xml, lib), Ptr{lattis_graph_raw}, (Cstring, Cstring), c_xml, c_name)
    end
    ptr == C_NULL && error(checked_last_error())
    return ptr
end

function _to_xml(symbol::Symbol, name::AbstractString, rawptr)::String
    _with_lib() do lib
        c_name = Base.cconvert(Cstring, name)
        GC.@preserve c_name begin
            ptr = ccall((symbol, lib), Ptr{Cchar}, (Cstring, typeof(rawptr)), Base.unsafe_convert(Cstring, c_name), rawptr)
            ptr == C_NULL && error(checked_last_error())
            try
                return unsafe_string(ptr)
            finally
                ccall((:lattis_string_free, lib), Cvoid, (Ptr{Cchar},), ptr)
            end
        end
    end
end

basis_to_xml_raw(name::AbstractString, rawptr::Ptr{lattis_basis_raw}) = _to_xml(:lattis_basis_to_xml, name, rawptr)
unitcell_to_xml_raw(name::AbstractString, rawptr::Ptr{lattis_unitcell_raw}) = _to_xml(:lattis_unitcell_to_xml, name, rawptr)
graph_to_xml_raw(name::AbstractString, rawptr::Ptr{lattis_graph_raw}) = _to_xml(:lattis_graph_to_xml, name, rawptr)

free_basis_raw(ptr::Ptr{lattis_basis_raw}) = _with_lib(lib -> ccall((:lattis_basis_raw_free, lib), Cvoid, (Ptr{lattis_basis_raw},), ptr))
free_unitcell_raw(ptr::Ptr{lattis_unitcell_raw}) = _with_lib(lib -> ccall((:lattis_unitcell_raw_free, lib), Cvoid, (Ptr{lattis_unitcell_raw},), ptr))
free_graph_raw(ptr::Ptr{lattis_graph_raw}) = _with_lib(lib -> ccall((:lattis_graph_raw_free, lib), Cvoid, (Ptr{lattis_graph_raw},), ptr))

end # module WrapFFI
