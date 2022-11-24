check :: (condition : bool, message : string = "Condition not met!", print_args : ..Any) #expand {
  if !condition {
    error(message, ..print_args);
  }
}

test_print :: (message : string, print_args : ..Any) #expand {
  print_color(tprint("TEST: %", message), ..print_args, FOREGROUND_BLUE);
}

correct_print :: (message : string, print_args : ..Any) #expand {
  print_color(message, ..print_args, FOREGROUND_GREEN);
}

validate_basis :: (basis_dir : string, geometry_dir : string) {

  basis_path := sprint("%03-21g.gbs", basis_dir);
  test_print("Opening basis file '%'\n", basis_path);
  basis_params := read_basis_file(basis_path);
  defer free(basis_params);

  geometry_path := sprint("%hf.xyz", geometry_dir);
  test_print("Opening basis file '%'\n", geometry_path);
  atoms, geometry := read_geometry_from_xyz_file(geometry_path);
  defer array_free(atoms);
  defer array_free(geometry);

  basis := create_basis(*basis_params, atoms);
  defer free(basis);


  // Actual validation
  test_print("Checking that shells have correct angular momenta...");
  for *shell, i : basis.shells {
    check(i == shell.angular_momentum, "% != %\n", i, shell.angular_momentum);
  }
  correct_print("PASSED\n");
}

#scope_file

#import "chemistry";
#import "util"; // for I/O

#import "Basic";
#import "Print_Color";
