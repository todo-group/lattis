**Python Bindings**

The Python package is built with **PyO3 + maturin** from the workspace crate:

```text
rust/lattis-python
```

It wraps the Rust `lattis` crate directly. The separate `lattis-ffi` crate is
kept for C++ compatibility through the C ABI.

**Packaging**

The PyPI distribution and Python import name are both:

```text
lattis
```

Package versioning is centralized in the root `Cargo.toml`:

```toml
[workspace.package]
version = "x.y.z"
```

Rust crates inherit that version with `version.workspace = true`, Python gets it
through maturin's dynamic version support, and CMake reads it for the C++
package version.

**Python API**

Python exposes:

```python
Basis
Unitcell
graph
Boundary
```

Constructors:

```python
Basis.simple(dim)
Basis(matrix)

Unitcell(dim)
Unitcell.simple(dim)

graph(dim)
graph.simple(dim, length)
graph.fully_connected(num_sites)
graph.from_basis_unitcell_extent(basis, unitcell, extent, boundary)
graph.from_basis_unitcell_length(basis, unitcell, length, boundary)
```

graph methods and properties:

```python
graph.dimension
graph.num_sites
graph.num_bonds
graph.site_type(i)
graph.coordinate(i)
graph.num_neighbors(i)
graph.neighbor(i, k)
graph.neighbor_bond(i, k)
graph.bond_type(i)
graph.source(i)
graph.target(i)
graph.edge_sites(i)
graph.add_site(coordinate, site_type=0)
graph.add_bond(source, target, bond_type=0)
```

Bulk accessors:

```python
graph.coordinates()
graph.coordinates_list()
graph.site_types()
graph.edges()
graph.bond_types()
```

**XML API**

Module-level functions:

```python
read_basis_from_string(xml, name)
read_unitcell_from_string(xml, name)
read_graph_from_string(xml, name)

read_basis_from_file(path, name)
read_unitcell_from_file(path, name)
read_graph_from_file(path, name)

write_basis_to_string(name, basis)
write_unitcell_to_string(name, unitcell)
write_graph_to_string(name, graph)
```

Class helpers:

```python
Basis.from_xml(...)
Basis.from_xml_file(...)
Unitcell.from_xml(...)
Unitcell.from_xml_file(...)
graph.from_xml(...)
graph.from_xml_file(...)

basis.to_xml(...)
unitcell.to_xml(...)
graph.to_xml(...)
```

**NumPy Support**

The bindings return NumPy arrays for bulk data:

- basis matrix as shape `(dim, dim)`
- graph coordinates as shape `(num_sites, dim)`
- edges as shape `(num_bonds, 2)`
- site and bond types as integer arrays

**Errors**

The Python boundary converts invalid user inputs into Python exceptions:

```python
ValueError
IndexError
RuntimeError
```

This keeps Rust panics from crossing into Python for common invalid dimensions,
indices, lengths, and XML failures.

**Local Development**

Install the editable Python extension:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install maturin numpy
.venv/bin/python -m maturin develop
```

Run tests:

```sh
.venv/bin/python -m unittest discover -s python/tests
```

Smoke test:

```sh
.venv/bin/python -c "import lattis; print(lattis.graph.simple(2, 4).num_sites)"
```

**Example**

```python
import lattis

g = lattis.graph.simple(2, 4)

assert g.dimension == 2
assert g.num_sites == 16
assert g.num_bonds == 32
print(g.coordinate(0))
print(g.edges())
```
