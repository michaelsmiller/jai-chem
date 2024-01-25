#scope_export

check :: (condition : bool, message : string = "Condition not met!", print_args : ..Any) #expand {
  if !condition {
    error(message, ..print_args);
  }
}

check_equals :: (a : Any, b : Any) #expand {
  check(a == b, "% != %", a, b);
}

check_close :: (a : f64, b : f64, epsilon : f64 = 1.0E-10) #expand {
  diff := Math.abs(a - b);
  if diff > epsilon
    error("% != % (|x - y| > %)", a, b, formatFloat(epsilon, mode=.SCIENTIFIC));
}

test_print :: (message : string, print_args : ..Any) #expand {
  log_info(tprint("%", message), ..print_args, type = .TITLE);
}

correct_print :: (message : string, print_args : ..Any) #expand {
  log_info(message, ..print_args, type=.SUCCESS);
}

perform_test :: (message : string, code : Code) #expand {
  test_print("%...", message);
  #insert code;
  correct_print("PASSED\n");
}

get_test_basis :: () -> Basis, [] Vector3 {
  basis_path := sprint("%03-21g.gbs", BASIS_DIR);
  log("Opening basis file '%'\n", basis_path);
  basis_params := read_basis_file(basis_path);
  defer free(basis_params);

  geometry_path := sprint("%hf.xyz", GEOMETRY_DIR);
  log("Opening basis file '%'\n", geometry_path);
  atoms, geometry := read_geometry_from_xyz_file(geometry_path);
  defer array_free(atoms);

  basis := create_basis(*basis_params, atoms);
  return basis, geometry;
}

#scope_file

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

Math :: #import "Math";

#import "Basic";
