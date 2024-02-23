#scope_export

GEOMETRY_DIR :: #run sprint("%test/geometry/", BASE_DIR);
TEST_DATA_DIR :: #run sprint("%test/data/", BASE_DIR);

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

read_data_file :: (path: string) -> Matrix {
  n := -1;
  m := -1;
  matrix : Matrix = ---;

  file_data, success := File.read_entire_file(path);
  assert(success);

  lines := String.split(file_data, cast(u8)#char "\n");
  i := -1;
  for line0: lines {
    line := String.trim(line0);
    if line == "" continue;
    if line[0] == #char "#" continue;

    defer i += 1;

    if i == -1 {
      success, m_string, n_string := String.split_from_left(line, cast(u8)#char " ");
      assert(success);
      m = to_integer(m_string);
      n = to_integer(n_string);
      matrix = create(m, n);
      continue;
    }

    assert(i >= 0);

    value_strings := String.split(line, cast(u8)#char " ");
    j := 0;
    for value_string: value_strings if value_string != "" {
      defer j += 1;
      value := string_to_float64(value_string);
      set(*matrix, i, j, value);
    }
  }
  return matrix;
}

#scope_file

#import "math"; // for Vector3, Matrix
#import "chemistry";
#import "util"; // for I/O, paths

#import "Basic"; // for sprint
String :: #import "String";
File :: #import "File";
