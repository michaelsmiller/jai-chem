#scope_export

test_ss_integral :: () {
  test_print("Checking that basis pairs get created correctly");

  basis, geometry := get_test_basis();
  defer free(basis);
  defer array_free(geometry);

  pairs := create_basis_pairs(*basis);
  defer free(pairs);
  update_basis_pairs(*pairs, geometry);

  // overlap of an s orbital with itself should be 1
  for *subshell: basis.shells[0].subshells for *cgto: subshell.cgtos {
    ra := geometry[subshell.i_atom];
    integral : f64;
    for *gto: cgto.gtos {
      integral += integrate_ss_overlap(gto.contraction_coefficient, gto.contraction_coefficient, gto.exponent, gto.exponent, ra, ra);
    }
    check_close(integral, cast(f64)1);
  }

  check(true);

} @Test

#scope_file

#import "test_util"; // for setting up the specific basis
#import "check";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3
#import "integrals";

#import "Basic";
