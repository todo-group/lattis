module Lattis

include("wrap_ffi.jl")
using .WrapFFI

export Basis, Unitcell, Graph
export has_liblattis, liblattis_path
export basis_from_xml, unitcell_from_xml, graph_from_xml
export to_xml, close
export dimension, num_sites, num_bonds

mutable struct Basis
    raw::Ptr{WrapFFI.lattis_basis_raw}
end

mutable struct Unitcell
    raw::Ptr{WrapFFI.lattis_unitcell_raw}
end

mutable struct Graph
    raw::Ptr{WrapFFI.lattis_graph_raw}
end


function Basis(raw::Ptr{WrapFFI.lattis_basis_raw})
    obj = Basis(raw)
    finalizer(obj) do x
        close(x)
    end
    return obj
end

function Unitcell(raw::Ptr{WrapFFI.lattis_unitcell_raw})
    obj = Unitcell(raw)
    finalizer(obj) do x
        close(x)
    end
    return obj
end

function Graph(raw::Ptr{WrapFFI.lattis_graph_raw})
    obj = Graph(raw)
    finalizer(obj) do x
        close(x)
    end
    return obj
end

basis_from_xml(xml::AbstractString, name::AbstractString) = Basis(WrapFFI.basis_from_xml_raw(xml, name))
unitcell_from_xml(xml::AbstractString, name::AbstractString) = Unitcell(WrapFFI.unitcell_from_xml_raw(xml, name))
graph_from_xml(xml::AbstractString, name::AbstractString) = Graph(WrapFFI.graph_from_xml_raw(xml, name))

function close(b::Basis)
    if b.raw != C_NULL
        WrapFFI.free_basis_raw(b.raw)
        b.raw = Ptr{WrapFFI.lattis_basis_raw}(C_NULL)
    end
    return nothing
end

function close(u::Unitcell)
    if u.raw != C_NULL
        WrapFFI.free_unitcell_raw(u.raw)
        u.raw = Ptr{WrapFFI.lattis_unitcell_raw}(C_NULL)
    end
    return nothing
end

function close(g::Graph)
    if g.raw != C_NULL
        WrapFFI.free_graph_raw(g.raw)
        g.raw = Ptr{WrapFFI.lattis_graph_raw}(C_NULL)
    end
    return nothing
end

function to_xml(name::AbstractString, b::Basis)::String
    b.raw == C_NULL && error("Basis is closed")
    return WrapFFI.basis_to_xml_raw(name, b.raw)
end

function to_xml(name::AbstractString, u::Unitcell)::String
    u.raw == C_NULL && error("Unitcell is closed")
    return WrapFFI.unitcell_to_xml_raw(name, u.raw)
end

function to_xml(name::AbstractString, g::Graph)::String
    g.raw == C_NULL && error("Graph is closed")
    return WrapFFI.graph_to_xml_raw(name, g.raw)
end

function dimension(b::Basis)::Int
    b.raw == C_NULL && error("Basis is closed")
    return Int(unsafe_load(b.raw).dim)
end

function dimension(u::Unitcell)::Int
    u.raw == C_NULL && error("Unitcell is closed")
    return Int(unsafe_load(u.raw).dim)
end

function dimension(g::Graph)::Int
    g.raw == C_NULL && error("Graph is closed")
    return Int(unsafe_load(g.raw).dim)
end

function num_sites(u::Unitcell)::Int
    u.raw == C_NULL && error("Unitcell is closed")
    return Int(unsafe_load(u.raw).num_sites)
end

function num_bonds(u::Unitcell)::Int
    u.raw == C_NULL && error("Unitcell is closed")
    return Int(unsafe_load(u.raw).num_bonds)
end

function num_sites(g::Graph)::Int
    g.raw == C_NULL && error("Graph is closed")
    return Int(unsafe_load(g.raw).num_sites)
end

function num_bonds(g::Graph)::Int
    g.raw == C_NULL && error("Graph is closed")
    return Int(unsafe_load(g.raw).num_bonds)
end

end # module Lattis
