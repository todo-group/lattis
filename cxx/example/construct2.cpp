/*
   Copyright (C) 2019 by Synge Todo <wistaria@phys.s.u-tokyo.ac.jp>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#include <iostream>
#include "lattis/graph.hpp"

int main() {
  lattis::basis_t bs(1, 1); bs << 1; // 1x1 matrix
  lattis::basis basis(bs);
  lattis::unitcell unitcell(1);
  unitcell.add_site(lattis::coordinate(0), 0);
  unitcell.add_bond(0, 0, lattis::offset(1), 0);
  lattis::span_t span(1, 1); span << 16; // 1x1 matrix
  std::vector<lattis::boundary_t> boundary(1, lattis::boundary_t::periodic);
  lattis::graph lat(basis, unitcell, span, boundary);
  lat.print(std::cout);
}
