run_tests :: () {
  print("------------------------------------\nRunning through test suite\n---------------------------\n");
  validate_basis();
  validate_basis_pairs();
}

#load "basis.jai";
