run_tests :: () {
  log_info("------------------------------------\nRunning through test suite\n---------------------------\n");
  validate_basis();
  validate_basis_pairs();
}

#load "basis.jai";
