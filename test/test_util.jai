#scope_export

get_test_basis :: () -> Basis, [] Vector3 {
  basis_path := sprint("%03-21g.gbs", BASIS_DIR);
  basis_params := read_basis_file(basis_path);
  defer free(basis_params);

  geometry_path := sprint("%hf.xyz", GEOMETRY_DIR);
  atoms, geometry := read_geometry_from_xyz_file(geometry_path);
  defer array_free(atoms);

  basis := create_basis(*basis_params, atoms);
  return basis, geometry;
}

GEOMETRY_DIR :: #run sprint("%test/geometry/", BASE_DIR);

#scope_file

#import "math"; // for Vector3
#import "chemistry";
#import "util"; // for I/O, paths

#import "Basic"; // for sprint
