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

ForRange :: struct {
  a, b, delta: f64;
  n : int;
}

range :: (a: f64, b: f64, n: int=0, delta: f64 = 0) -> ForRange {
  assert(a != b);
  assert(n == 0 || delta == 0);

  range := ForRange.{a, b, delta, n};
  if n > 0
    range.delta = (b-a) / (n-1);
  else {
    range.n = cast(int)((b-a)/delta) + 1;
  }
  assert(range.n >= 0);
  assert(range.delta != 0);
  return range;
}

for_expansion :: (range: ForRange, body: Code, flags: For_Flags) #expand {
  // go from a to b, regardless of direction
  increasing := range.b > range.a;
  for i: 0..range.n {
    x : f64 = range.a + i * range.delta;
    if  increasing && x > range.b break;
    if !increasing && x < range.b break;

    `it_index := i;
    `it := x;

    #insert body;
  }
}

GEOMETRY_DIR :: #run sprint("%test/geometry/", BASE_DIR);

#scope_file

#import "math"; // for Vector3
#import "chemistry";
#import "util"; // for I/O, paths

#import "Basic"; // for sprint
