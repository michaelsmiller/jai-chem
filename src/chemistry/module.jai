read_geometry_from_xyz_file :: (filename : string) -> [] Atom , [] Vector3 {
  s, read_success := File.read_entire_file(filename);
  if !read_success
    error("Cannot read file '%'\n", filename);
  lines := String.split(s, cast(u8)(#char "\n"));
  atoms : [..] Atom;
  geometry : [..] Vector3;

  n := 0;
  for * line0, line_no : lines {
    if line_no == 1 continue; // always ignore second line of xyz files
    line := String.trim(<<line0); // remove leading and trailing spaces
    // first line contains number of atoms
    if line_no == 0 {
      success := false;
      n, success = String.parse_int(*line);
      if !success
        error("Expected an integer on line 2 '%', got '%'\n", filename, line);
      array_reserve(*atoms, n);
      continue;
    }

    split := String.split(line, cast(u8)(#char " "));
    if split.count <= 1 break;
    assert(split.count >= 4);
    element_name := split[0];
    element : Element = name_to_element(element_name);
    info := get_element_info(element);
    atom := array_add(*atoms);
    position := array_add(*geometry);
    atom.element = xx element; // @todo: figure out why we need to autocast here
    atom.mass = info.mass;
    atom.nuclear_charge = cast(f64) info.atomic_number;
    j := 0;
    for * token, i : split if i > 0 && token.count > 0 {
      number_in_angstroms, success := String.parse_float(token);
      if !success
        error("Failed to get a float64 out of '%'\n", token);
      position.vec[j] = number_in_angstroms * ANGSTROM_TO_BOHR;
      j += 1;
    }
    assert(j == 3);
  }
  assert(n == atoms.count);
  return atoms, geometry;
}

#load "atom.jai";
#load "basis.jai";
#load "element.jai";

#scope_file

File :: #import "File";
String :: #import "String";

#import "constants";
