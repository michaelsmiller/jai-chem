// @todo: clean this up so that C is optional, since for overlap there *is* no point of evaluation
//        or rather, the integral is the same everywhere.
compute_overlap :: (basis_pairs : *BasisPairs, C : Vector3, matrix : *Matrix) {
  p : PairParameters;
  log("There are % pairs of CGTOs total\n", basis_pairs.cgto_pairs.count);
  // For each shell combination la, lb, we loop through all pairs of subshells
  // For each pair of subshells we loop through all pairs of orbitals, then
  // all pairs of primitives.
  for *shell_pair : basis_pairs.shell_pairs {
    log("Shell pair %:%\n", shell_pair.la, shell_pair.lb);
    for *subshell_pair : shell_pair.subshell_pairs {
      log("Subshell pair %:%\n", subshell_pair.atom_a, subshell_pair.atom_b);
      p.ab2 = subshell_pair.ab2;
      for *cgto_pair : subshell_pair.cgto_pairs {
        a := compute_gaussian_index(shell_pair.la, cgto_pair.ma);
        b := compute_gaussian_index(shell_pair.lb, cgto_pair.mb);

        result := get(matrix, cgto_pair.index_a, cgto_pair.index_b);
        defer set(matrix, cgto_pair.index_a, cgto_pair.index_b, result);
        for *gto_pair : cgto_pair.gto_pairs {
          p.zeta_a = gto_pair.zeta_a;
          p.zeta_b = gto_pair.zeta_b;
          zeta    := gto_pair.zeta;

          P := gto_pair.P;
          p.PA = P - subshell_pair.A;
          p.PB = P - subshell_pair.B;
          p.PC = P - C;
          p.xi = gto_pair.xi;
          p.coefficient = gto_pair.coefficient;
          integral := integrate_primitives(a, b, *p);
          log("% => %\n", p, integral);
          result += integral;
        }
      }
    }
  }
  copy_over_diagonal(matrix, upper_right_to_lower_left=true);
}

#scope_file

#import "Basic"; // debugging, really
Math :: #import "Math";

#import "chemistry";
#import "util"; // f64
#import "math"; // Vector3
#import "constants";
#import,file "gaussian_integral.jai";
