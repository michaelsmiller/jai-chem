run_tests :: () {
  log_info("------------------------------------\nRunning through test suite\n---------------------------\n");
  validate_constants();
  validate_geometry_parsing();
  validate_basis();
  validate_basis_pairs();
}

#import "util"; // for log_info
#import,file "basis.jai";
#import,file "parsing.jai";
