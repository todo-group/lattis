using Test
using Lattis

@testset "Lattis bindings" begin
    @test has_liblattis() isa Bool

    if !has_liblattis()
        @info "Skipping FFI integration tests: set LIBLATTIS_PATH to liblattis_ffi shared library"
        return
    end

    sample = """
    <LATTICES>
      <BASIS name=\"square\"><VECTOR>1 0</VECTOR><VECTOR>0 1</VECTOR></BASIS>
      <UNITCELL name=\"uc\" dimension=\"2\">
        <VERTEX type=\"0\"><COORDINATE>0 0</COORDINATE></VERTEX>
      </UNITCELL>
      <LATTICEGRAPH name=\"g\" dimension=\"2\">
        <VERTEX type=\"0\"><COORDINATE>0 0</COORDINATE></VERTEX>
      </LATTICEGRAPH>
    </LATTICES>
    """

    b = basis_from_xml(sample, "square")
    @test dimension(b) == 2
    @test occursin("BASIS", to_xml("square2", b))
    close(b)

    u = unitcell_from_xml(sample, "uc")
    @test dimension(u) == 2
    @test num_sites(u) == 1
    @test num_bonds(u) == 0
    @test occursin("UNITCELL", to_xml("uc2", u))
    close(u)

    g = graph_from_xml(sample, "g")
    @test dimension(g) == 2
    @test num_sites(g) == 1
    @test num_bonds(g) == 0
    @test occursin("LATTICEGRAPH", to_xml("g2", g))
    close(g)
end
