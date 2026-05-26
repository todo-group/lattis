#ifndef LATTIS_RUST_XML_FFI_H
#define LATTIS_RUST_XML_FFI_H

#include <cstddef>
#include <cstdint>

extern "C" {

struct lattis_basis_raw {
  std::size_t dim;
  std::size_t values_len;
  double* values;
};

struct lattis_unitcell_raw {
  std::size_t dim;
  std::size_t num_sites;
  int* site_types;
  std::size_t site_coordinates_len;
  double* site_coordinates;
  std::size_t num_bonds;
  std::size_t* bond_sources;
  std::size_t* bond_targets;
  int* bond_types;
  std::size_t bond_offsets_len;
  std::int64_t* bond_offsets;
};

struct lattis_graph_raw {
  std::size_t dim;
  std::size_t num_sites;
  int* site_types;
  std::size_t site_coordinates_len;
  double* site_coordinates;
  std::size_t num_bonds;
  std::size_t* bond_sources;
  std::size_t* bond_targets;
  int* bond_types;
};

char* lattis_basis_to_xml(const char* name, const lattis_basis_raw* raw);
lattis_basis_raw* lattis_basis_from_xml(const char* xml, const char* name);
void lattis_basis_raw_free(lattis_basis_raw* raw);

char* lattis_unitcell_to_xml(const char* name, const lattis_unitcell_raw* raw);
lattis_unitcell_raw* lattis_unitcell_from_xml(const char* xml, const char* name);
void lattis_unitcell_raw_free(lattis_unitcell_raw* raw);

char* lattis_graph_to_xml(const char* name, const lattis_graph_raw* raw);
lattis_graph_raw* lattis_graph_from_xml(const char* xml, const char* name);
void lattis_graph_raw_free(lattis_graph_raw* raw);

void lattis_string_free(char* ptr);
char* lattis_last_error_message();

}

#endif
