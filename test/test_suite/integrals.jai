#scope_export

test_overlap_integral_normalized :: () {
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

  p : PairParameters;
  for *shell : basis.shells {
    for *subshell: shell.subshells {
      for *cgto: subshell.cgtos {
        total_integral : f64 = 0;
        for *gto1: cgto.gtos {
          for *gto2: cgto.gtos if gto2 >= gto1 {
            p.zeta_a = gto1.exponent;
            p.zeta_b = gto2.exponent;
            p.xi = p.zeta_a * p.zeta_b / (p.zeta_a + p.zeta_b);
            p.coefficient = gto1.contraction_coefficient * gto2.contraction_coefficient;
            a := compute_gaussian_index(shell.angular_momentum, cgto.m);
            b := a;
            primitive_integral := integrate_primitives(a, b, *p);
            total_integral += primitive_integral;
          }
        }
        check_close(total_integral, cast(f64)1, prefix=tprint("% % ", shell.angular_momentum, subshell.i_atom));
      }
    }
  }

} @Test

#scope_file

#import "test_util"; // for setting up the specific basis
#import "check";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3
#import "integrals";

#import "Basic";
