import tempfile
import unittest
from pathlib import Path

import numpy as np

import lattis


class BindingTests(unittest.TestCase):
    def test_simple_graphs(self):
        chain = lattis.graph.simple(1, 16)
        self.assertEqual(chain.dimension, 1)
        self.assertEqual(chain.num_sites, 16)
        self.assertEqual(chain.num_bonds, 16)

        square = lattis.graph.simple(2, 4)
        self.assertEqual(square.dimension, 2)
        self.assertEqual(square.num_sites, 16)
        self.assertEqual(square.num_bonds, 32)
        self.assertEqual(square.edge_sites(0), (0, 1))

    def test_numpy_bulk_accessors(self):
        basis = lattis.Basis.simple(2)
        graph = lattis.graph.simple(2, 4)

        self.assertIsInstance(basis.matrix(), np.ndarray)
        self.assertEqual(basis.matrix().shape, (2, 2))
        self.assertEqual(graph.coordinates().shape, (16, 2))
        self.assertEqual(graph.edges().shape, (32, 2))
        self.assertEqual(graph.site_types().shape, (16,))
        self.assertEqual(graph.bond_types().shape, (32,))
        self.assertEqual(graph.site_types().dtype, np.dtype("int32"))
        self.assertIsInstance(graph.coordinates_list(), list)

    def test_unitcell_and_generic_construction(self):
        basis = lattis.Basis([[1.0, 0.0], [0.0, 1.0]])
        cell = lattis.Unitcell(2)
        self.assertEqual(cell.add_site([0.0, 0.0]), 0)
        self.assertEqual(cell.add_bond(0, 0, [1, 0]), 0)
        self.assertEqual(cell.add_bond(0, 0, [0, 1]), 1)

        graph = lattis.graph.from_basis_unitcell_extent(
            basis,
            cell,
            [4, 4],
            [lattis.Boundary.Periodic, lattis.Boundary.Periodic],
        )
        self.assertEqual(graph.num_sites, 16)
        self.assertEqual(graph.num_bonds, 32)

    def test_xml_round_trips(self):
        basis = lattis.Basis.simple(2)
        cell = lattis.Unitcell.simple(2)
        graph = lattis.graph.simple(2, 4)

        basis_xml = lattis.write_basis_to_string("basis", basis)
        cell_xml = cell.to_xml("cell")
        graph_xml = graph.to_xml("graph")

        self.assertEqual(lattis.read_basis_from_string(basis_xml, "basis").dimension, 2)
        self.assertEqual(lattis.Unitcell.from_xml(cell_xml, "cell").num_bonds, 2)
        self.assertEqual(lattis.graph.from_xml(graph_xml, "graph").num_sites, 16)

        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "graph.xml"
            path.write_text(graph_xml)
            loaded = lattis.read_graph_from_file(path, "graph")
            self.assertEqual(loaded.num_bonds, 32)
            self.assertEqual(lattis.graph.from_xml_file(path, "graph").num_sites, 16)

    def test_errors_are_python_exceptions(self):
        graph = lattis.graph.simple(2, 4)
        with self.assertRaises(IndexError):
            graph.site_type(graph.num_sites)
        with self.assertRaises(IndexError):
            graph.neighbor(0, graph.num_neighbors(0))
        with self.assertRaises(ValueError):
            graph.add_site([0.0])
        with self.assertRaises(ValueError):
            lattis.graph.simple(2, 0)
        with self.assertRaises(ValueError):
            lattis.read_graph_from_string("<LATTICES/>", "missing")


if __name__ == "__main__":
    unittest.main()
