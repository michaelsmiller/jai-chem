run_tests :: (basis_dir := "basis/", geometry_dir := "geometry/") {
  print("------------------------------------\nRunning through test suite\n---------------------------\n");
  validate_basis(basis_dir, geometry_dir);
}

#load "basis.jai";
