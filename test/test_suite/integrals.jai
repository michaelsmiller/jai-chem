#scope_export

test_ss_integral :: () {
  test_print("Checking ss overlap integrals are 1");

  basis, geometry := get_test_basis();
  defer free(basis);
  defer array_free(geometry);

  pairs := create_basis_pairs(*basis);
  defer free(pairs);
  update_basis_pairs(*pairs, geometry);

  // overlap of an orbital with itself should be 1
  origin := Vector3.{0, 0, 0};
  n := basis.cgtos.count;
  overlap_matrix := create(n);
  compute_overlap(*pairs, origin, *overlap_matrix);
  check_close(get(*overlap_matrix, 0, 0), cast(f64)1);
  check_close(get(*overlap_matrix, 1, 1), cast(f64)1);
  for i : 0..n-1 check_close(get(*overlap_matrix, i, i), cast(f64)1, prefix=tprint("% ", i));

} @Test

#scope_file

#import "test_util"; // for setting up the specific basis
#import "check";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3
#import "integrals";

#import "Basic";
