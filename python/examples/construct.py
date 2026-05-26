import lattis


def describe(name, graph):
    print(f"{name}:")
    print(f"  dimension = {graph.dimension}")
    print(f"  sites     = {graph.num_sites}")
    print(f"  bonds     = {graph.num_bonds}")
    print(f"  first edge = {graph.edge_sites(0)}")


def main():
    chain = lattis.graph.simple(1, 16)
    describe("periodic chain", chain)

    square = lattis.graph.simple(2, 4)
    describe("periodic square lattice", square)
    print(f"  coordinates shape = {square.coordinates().shape}")
    print(f"  edges shape       = {square.edges().shape}")

    basis = lattis.Basis([[1.0, 0.0], [0.0, 1.0]])
    unitcell = lattis.Unitcell(2)
    unitcell.add_site([0.0, 0.0])
    unitcell.add_bond(0, 0, [1, 0])
    unitcell.add_bond(0, 0, [0, 1])

    generic_square = lattis.graph.from_basis_unitcell_extent(
        basis,
        unitcell,
        [4, 4],
        [lattis.Boundary.Periodic, lattis.Boundary.Periodic],
    )
    describe("generic square lattice", generic_square)

    complete = lattis.graph.fully_connected(10)
    describe("fully connected graph", complete)


if __name__ == "__main__":
    main()
